import 'dart:collection';

import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/shapes/parametric_path.dart';
import 'package:rive_core/shapes/path.dart' as core;
import 'package:rive_core/shapes/points_path.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/rive/stage/items/stage_path.dart';
import 'package:rive_editor/rive/stage/items/stage_path_vertex.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/auto_tool.dart';
import 'package:rive_editor/widgets/inspector/inspect_skin.dart';
import 'package:rive_editor/widgets/inspector/inspect_vertices.dart';
import 'package:rive_editor/widgets/inspector/inspector_builder.dart';
import 'package:utilities/restorer.dart';

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
  final List<InspectorBuilder> _editingPathInspectors = [
    VertexInspector(),
    InspectSkin(),
  ];
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

  Restorer _selectionHandlerRestorer;

  VertexEditor(this.file, this.stage) {
    file.core.addDelegate(this);
    file.addActionHandler(_handleAction);
    stage.soloListenable.addListener(_soloChanged);
  }

  bool _changeMode(VertexEditorMode mode) {
    if (mode == _mode.value) {
      return false;
    }
    switch (_mode.value = mode) {
      case VertexEditorMode.editingPath:
        stage.soloListenable.addListener(_soloChanged);
        _selectionHandlerRestorer =
            stage.addSelectionHandler(_selectionHandler);
        break;
      case VertexEditorMode.off:
      default:
        // Make sure everything's turned off
        _turnOff();
        stage.solo(null);
        stage.soloListenable.removeListener(_soloChanged);
        _selectionHandlerRestorer?.restore();
        _editingPaths.value = null;
        break;
    }

    return true;
  }

  bool doneEditing() => _changeMode(VertexEditorMode.off);

  bool _selectionHandler(StageItem item) {
    var path = _creatingPath.value;
    if (item is StagePathVertex && path?.vertices?.first == item.component) {
      path.isClosed = true;
      path.editingMode = PointsPathEditMode.editing;
      path.context.captureJournalEntry();
    }
    return false;
  }

  void _soloChanged() {
    // Stage's solo has changed and it has no solo items, we need to make sure
    // that if our mode is not off, then we should force everything off
    if (stage.soloItems == null && _mode.value != VertexEditorMode.off) {
      _turnOff();
    }
  }

  void _turnOff() {
    // Copy them out before we null them.
    var paths = _editingPaths.value;
    if (paths == null) {
      return;
    }
    _changeMode(VertexEditorMode.off);
    if (!file.core.isApplyingJournalEntry) {
      // copy to prevent editing during iteration in onObjectRemoved.
      var pathsCopy = paths.toList(growable: false);
      _editingPaths.value = null;
      // We only want to change the path's edit mode if we're not in the
      // middle of a undo/redo.
      for (final path in pathsCopy) {
        path.editingMode = PointsPathEditMode.off;
      }
      file.core.captureJournalEntry();
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

  /// Operations that require the vertex editor to have completed syncing a
  /// change to solo can call this to make sure debounced operations complete
  /// synchronously.
  void ensureSoloSync() {
    stage.debounceAccelerate(_syncSolo);
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
      }
    }

    // In this case, something is toggling editing back on but the vertex
    // editor isn't currently editing paths. So we want to toggle it back
    // on.
    else if (_editingPaths.value == null) {
      // Put us into editing path mode.
      _changeMode(VertexEditorMode.editingPath);
      _editingPaths.value = HashSet<PointsPath>.from(<PointsPath>[path]);
    } else {
      // Editing/Creating is on, make sure the path is in the editing set.
      _editingPaths.value.add(path);
    }
    stage.debounce(_syncSolo);
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
    // Capture journal entry to ensure any changes to edit mode are captured.
    stage.file.core.captureJournalEntry();

    // Sync solo. It's ok if this is called "too often" as stage.solo does a
    // iterable equality check.
    stage.solo(_editingPaths.value?.map((path) => path.stageItem));
  }

  void _editPaths(Iterable<core.Path> paths) {
    var pathsToEdit = HashSet<core.Path>.from(paths);

    // If we have any parametric paths, convert them to points paths (flatten
    // them).
    var parametricPaths = pathsToEdit.whereType<ParametricPath>();
    if (parametricPaths.isNotEmpty) {
      var pathsWithoutParametric = HashSet<core.Path>.from(paths);
      pathsWithoutParametric.removeAll(parametricPaths);
      pathsToEdit = pathsWithoutParametric;

      file.core.batchAdd(() {
        for (final parametricPath in parametricPaths) {
          var parent = parametricPath.parent;
          parametricPath.remove();
          var pointsPath = PointsPath()
            ..translation = parametricPath.translation
            ..rotation = parametricPath.rotation
            ..scale = parametricPath.scale
            ..childOrder = parametricPath.childOrder
            ..isClosed = parametricPath.isClosed;
          file.core.addObject(pointsPath);
          pointsPath.parent = parent;

          var vertices = parametricPath.vertices;
          for (final vertex in vertices) {
            file.core.addObject(vertex);
            vertex.parent = pointsPath;
          }

          pathsWithoutParametric.add(pointsPath);
        }
      });
      file.core.captureJournalEntry();
    }

    _editingPaths.value = HashSet<PointsPath>.from(pathsToEdit);
    _syncSolo();
    _changeMode(VertexEditorMode.editingPath);
    for (final path in _editingPaths.value) {
      path.editingMode = PointsPathEditMode.editing;
    }
  }

  bool activateForSelection({bool recursivePaths = false}) {
    // Stage doesn't have any solo items, see if there's a good candidate for
    // activating edit mode.

    // TODO: find out out what designers really want in regards to
    // activating edit mode.
    Set<StagePath> paths = {};

    for (final item in file.selection.items) {
      if (item is StagePath) {
        paths.add(item);
      } else if (recursivePaths &&
          item is StageItem &&
          item.component is ContainerComponent) {
        (item.component as ContainerComponent).forEachChild((child) {
          if (child.stageItem is StagePath) {
            paths.add(child.stageItem as StagePath);
            return false;
          }
          return true;
        });
      }
    }

    if (paths.isNotEmpty) {
      _editPaths(paths.map((stagePath) => stagePath.component).toList());

      if (paths.length == 1) {
        final type = RiveCoreContext.objectName(paths.first.component.coreType);
        file.showSelectionAlert('Editing ${paths.first.component.name} '
            '($type)');
      } else {
        file.showSelectionAlert('Editing multiple paths.');
      }
    }

    // swallow the event if we started editing paths (solo gets set to the
    // paths).
    return stage.soloItems != null;
  }

  bool deactivate() {
    // If we were editing, enter exits vertex editing mode and selects the
    // paths.
    var editingPaths = _editingPaths.value;
    if (editingPaths != null && editingPaths.isNotEmpty) {
      var toSelect = editingPaths
          .map<StageItem<Component>>(
              (path) => path.stageItem as StageItem<Component>)
          .toList();
      doneEditing();

      file.selection.selectMultiple(toSelect);

      if (toSelect.length == 1) {
        final type =
            RiveCoreContext.objectName(toSelect.first.component.coreType);
        file.showSelectionAlert(
            'Done editing ${toSelect.first.component.name} ($type)');
      } else {
        file.showSelectionAlert('Done editing paths.');
      }
      // Select the auto tool
      stage.tool = AutoTool.instance;
      return true;
    }
    return false;
  }

  bool _handleAction(ShortcutAction action) {
    switch (action) {
      case ShortcutAction.toggleEditMode:
        if (stage.soloItems == null) {
          return activateForSelection();
        }

        return deactivate();
    }
    return false;
  }

  void dispose() {
    _changeMode(VertexEditorMode.off);
    stage.cancelDebounce(_syncSolo);
    file.core.removeDelegate(this);
    file.removeActionHandler(_handleAction);
  }

  bool get isActive => _mode.value == VertexEditorMode.editingPath;

  List<InspectorBuilder> inspectorBuilders() {
    return isActive ? _editingPathInspectors : null;
  }
}
