import 'dart:collection';

import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/shapes/path.dart' as core;
import 'package:rive_core/shapes/points_path.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/rive/stage/items/stage_path.dart';
import 'package:rive_editor/rive/stage/items/stage_shape.dart';
import 'package:rive_editor/rive/stage/items/stage_vertex.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/widgets/inspector/inspect_vertices.dart';
import 'package:rive_editor/widgets/inspector/inspector_builder.dart';

// A manager that has a sense of what's currently being edited in stage solo
// mode. Meant to support shapes, paths, and meshes. It needs to track the set
// of edited paths so that the inspector can show the right state and apply
// custom operations like closing a path, always drawing that path as selected
// so we get the contour, etc.

enum VertexEditorMode {
  off,
  editingMesh,
  editingPath,
}

class VertexEditor with RiveFileDelegate {
  final List<InspectorBuilder> _editingPathInspectors = [VertexInspector()];
  final OpenFileContext file;
  final Stage stage;
  final ValueNotifier<HashSet<PointsPath>> _editingPaths =
      ValueNotifier<HashSet<PointsPath>>(null);
  ValueListenable<HashSet<PointsPath>> get editingPathsListenable =>
      _editingPaths;

  final ValueNotifier<VertexEditorMode> _mode =
      ValueNotifier<VertexEditorMode>(VertexEditorMode.off);
  ValueListenable<VertexEditorMode> get mode => _mode;

  final ValueNotifier<PointsPath> _creatingPath =
      ValueNotifier<PointsPath>(null);
  ValueListenable<PointsPath> get creatingPath => _creatingPath;
  Iterable<PointsPath> get editingPaths => _editingPaths.value;

  VertexEditor(this.file, this.stage) {
    file.core.addDelegate(this);
    file.addActionHandler(_handleAction);
    stage.soloListenable.addListener(_soloChanged);
  }

  void _changeMode(VertexEditorMode mode) {
    if (mode == _mode.value) {
      return;
    }
    switch (_mode.value = mode) {
      case VertexEditorMode.editingPath:
        stage.soloListenable.addListener(_soloChanged);
        stage.addSelectionHandler(_selectionHandler);
        break;
      case VertexEditorMode.off:
      default:
        stage.soloListenable.removeListener(_soloChanged);
        stage.removeSelectionHandler(_selectionHandler);
        stage.solo(null);
        break;
    }
  }

  void doneEditing() {
    _changeMode(VertexEditorMode.off);
  }

  bool _selectionHandler(StageItem item) {
    var path = _creatingPath.value;
    if (item is StageVertex && path?.vertices?.first == item.component) {
      path.isClosed = true;
      path.editingMode = PointsPathEditMode.editing;
      path.context.captureJournalEntry();
    }
    return false;
  }

  void _soloChanged() {
    if (stage.soloItems == null) {
      if (_mode.value != VertexEditorMode.off) {
        _changeMode(VertexEditorMode.off);
        if (!file.core.isApplyingJournalEntry) {
          // copy to prevent editing during iteration in onObjectRemoved.
          var pathsCopy = _editingPaths.value.toList(growable: false);
          _editingPaths.value = null;
          // We only want to change the path's edit mode if we're not in the
          // middle of a undo/redo.
          for (final path in pathsCopy) {
            path.editingMode = PointsPathEditMode.off;
          }
          file.core.captureJournalEntry();
        }
      }
    } else {
      switch (_mode.value) {
        case VertexEditorMode.editingPath:
          break;
        default:
          break;
      }
    }
  }

  @override
  void onObjectRemoved(Core object) {
    /// Called back whenever a core object is removed, use this to update the
    /// editing list if one of the items in it was removed.
    if (_editingPaths != null && object.coreType == PointsPathBase.typeKey) {
      var path = object as PointsPath;
      _updatePathEditMode(path, PointsPathEditMode.off);
    }
  }

  @override
  void onObjectAdded(Core object) {
    if (object.coreType == PointsPathBase.typeKey &&
        (object as PointsPath).editingMode != PointsPathEditMode.off) {
      var path = object as PointsPath;
      _updatePathEditMode(path, path.editingMode);
    }
  }

  void _updatePathEditMode(PointsPath path, PointsPathEditMode editMode) {
    // When a path is changed to being edited/created we want to add it to
    // the _editingPaths set. When it's set to off, we want to remove it
    // from the set.
    bool remove = false;
    switch (editMode) {
      case PointsPathEditMode.creating:
        _creatingPath.value = path;
        break;
      case PointsPathEditMode.editing:
        if (path == _creatingPath.value) {
          _creatingPath.value = null;
        }
        break;
      case PointsPathEditMode.off:
        remove = true;
        if (path == _creatingPath.value) {
          _creatingPath.value = null;
        }
        break;
    }

    if (remove) {
      if (_editingPaths.value?.remove(path) ?? false) {
        if (_editingPaths.value.isEmpty) {
          _editingPaths.value = null;
          _changeMode(VertexEditorMode.off);
        }
        stage.debounce(_syncSolo);
      }
    }

    // In this case, something is toggling editing back on but the vertex
    // editor isn't currently editing paths. So we want to toggle it back
    // on.
    else if (_editingPaths.value == null) {
      // Put us into editing path mode.
      _changeMode(VertexEditorMode.editingPath);
      _editingPaths.value = HashSet<PointsPath>.from(<PointsPath>[path]);
      stage.debounce(_syncSolo);
      // We're already editing paths, just make sure this one is in the set.
    } else if (_editingPaths.value.add(path)) {
      stage.debounce(_syncSolo);
    }
  }

  // This is called back whenever a property registered as being editorOnly in
  // the system is changed.
  @override
  void onEditorPropertyChanged(
      Core object, int propertyKey, Object from, Object to) {
    switch (propertyKey) {
      case PointsPathBase.editingModeValuePropertyKey:
        var path = object as PointsPath;
        _updatePathEditMode(path, path.editingMode);
        break;
    }
  }

  void _syncSolo() {
    stage.solo(_editingPaths.value?.map((path) => path.stageItem));
  }

  void _editPaths(Iterable<core.Path> paths) {
    // for now just get points paths, later flatten the others
    _editingPaths.value =
        HashSet<PointsPath>.from(paths.whereType<PointsPath>());
    _syncSolo();
    _changeMode(VertexEditorMode.editingPath);
    for (final path in _editingPaths.value) {
      path.editingMode = PointsPathEditMode.editing;
    }
  }

  bool _handleAction(ShortcutAction action) {
    switch (action) {
      case ShortcutAction.toggleEditMode:
        if (stage.soloItems == null) {
          // Stage doesn't have any solo items, see if there's a good candidate
          // for activating edit mode.

          // TODO: find out out what designers really want in regards to
          // activating edit mode.
          Set<StageShape> shapes = {};
          Set<StagePath> paths = {};

          for (final item in file.selection.items) {
            if (item is StageShape) {
              shapes.add(item);
            } else if (item is StagePath) {
              paths.add(item);
            }
          }

          if (shapes.isNotEmpty) {
            _editPaths(shapes.first.component.paths);
          } else if (paths.isNotEmpty) {
            _editPaths([paths.first.component]);
          }
        }

        return true;
    }
    return false;
  }

  void dispose() {
    _changeMode(VertexEditorMode.off);
    stage.cancelDebounce(_syncSolo);
    file.core.removeDelegate(this);
    file.removeActionHandler(_handleAction);
  }

  List<InspectorBuilder> inspectorBuilders() {
    return _mode.value == VertexEditorMode.editingPath
        ? _editingPathInspectors
        : null;
  }
}
