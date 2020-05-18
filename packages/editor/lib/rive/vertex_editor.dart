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
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';

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
  final OpenFileContext file;
  final Stage stage;
  HashSet<PointsPath> _editingPaths;

  final ValueNotifier<VertexEditorMode> _mode =
      ValueNotifier<VertexEditorMode>(VertexEditorMode.off);
  ValueListenable<VertexEditorMode> get mode => _mode;

  final ValueNotifier<PointsPath> _creatingPath =
      ValueNotifier<PointsPath>(null);
  ValueListenable<PointsPath> get creatingPath => _creatingPath;

  VertexEditor(this.file, this.stage) {
    file.core.addDelegate(this);
    file.addActionHandler(_handleAction);
    stage.soloListenable.addListener(_soloChanged);
  }

  void _soloChanged() {
    if (stage.soloItems == null) {
      if (_mode.value != VertexEditorMode.off) {
        _mode.value = VertexEditorMode.off;
        // copy to prevent editing during iteration in onObjectRemoved.

        var pathsCopy = _editingPaths.toList(growable: false);
        _editingPaths = null;

        for (final path in pathsCopy) {
          path.editingMode = PointsPathEditMode.off;
        }
        file.core.captureJournalEntry();
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
      print("PATH REMOVED");
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
        print("EDIT MODE CREATING");
        _creatingPath.value = path;
        break;
      case PointsPathEditMode.editing:
        print("EDIT MODE EDITING");
        if (path == _creatingPath.value) {
          _creatingPath.value = null;
        }
        break;
      case PointsPathEditMode.off:
        print("EDIT MODE OFF");
        remove = true;
        if (path == _creatingPath.value) {
          _creatingPath.value = null;
        }
        break;
    }

    if (remove) {
      if (_editingPaths?.remove(path) ?? false) {
        if (_editingPaths.isEmpty) {
          _editingPaths = null;
          _mode.value = VertexEditorMode.off;
        }
        stage.debounce(_syncSolo);
      }
    }

    // In this case, something is toggling editing back on but the vertex
    // editor isn't currently editing paths. So we want to toggle it back
    // on.
    else if (_editingPaths == null) {
      // Put us into editing path mode.
      _mode.value = VertexEditorMode.editingPath;
      _editingPaths = HashSet<PointsPath>.from(<PointsPath>[path]);
      stage.debounce(_syncSolo);
      // We're already editing paths, just make sure this one is in the set.
    } else if (_editingPaths.add(path)) {
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
    stage.solo(_editingPaths?.map((path) => path.stageItem));
  }

  void _editPaths(Iterable<core.Path> paths) {
    // for now just get points paths, later flatten the others
    _editingPaths = HashSet<PointsPath>.from(paths.whereType<PointsPath>());
    _syncSolo();
    _mode.value = VertexEditorMode.editingPath;
    for (final path in _editingPaths) {
      path.editingMode = PointsPathEditMode.editing;
    }
  }

  void closePath(PointsPath path) {
    path.isClosed = true;
    path.editingMode = PointsPathEditMode.editing;
    path.context.captureJournalEntry();
  }

  void startCreatingPath(PointsPath path) {
    // Set the solo item as the path we just created which will trigger updating
    // the editing components.
    _editingPaths ??= HashSet<PointsPath>();
    _editingPaths.add(path);
    print("EDITING PATHS START: $_editingPaths");
    path.editingMode = PointsPathEditMode.creating;
    _mode.value = VertexEditorMode.editingPath;
    stage.solo(_editingPaths.map((path) => path.stageItem));
    _creatingPath.value = path;
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
    stage.cancelDebounce(_syncSolo);
    file.core.removeDelegate(this);
    stage.soloListenable.removeListener(_soloChanged);
    file.removeActionHandler(_handleAction);
  }
}
