import 'dart:collection';

import 'package:core/core.dart';
import 'package:core/debounce.dart';
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

// A manager that has a sense of what's currently being edited in solo mode.
// Meant to support shapes, paths, and meshes. It needs to track the set of
// edited paths so that the inspector can show the right state and apply custom
// operations like closing a path, always drawing that path as selected so we
// get the contour, etc.

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
    if (stage.solo == null) {
      _mode.value = null;
      for (final path in _editingPaths) {
        path.editingMode = PointsPathEditMode.off;
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
  void onEditorPropertyChanged(
      Core object, int propertyKey, Object from, Object to) {
    switch (propertyKey) {
      case PointsPathBase.editingModeValuePropertyKey:
        var path = object as PointsPath;

        switch (path.editingMode) {
          case PointsPathEditMode.creating:
            _editingPaths.add(path);
            _creatingPath.value = path;
            break;
          case PointsPathEditMode.editing:
            _editingPaths.add(path);
            if (path == _creatingPath.value) {
              _creatingPath.value = null;
            }
            break;
          case PointsPathEditMode.off:
            _editingPaths.remove(path);
            if (path == _creatingPath.value) {
              _creatingPath.value = null;
            }
            break;
        }
        debounce(_syncSolo);
        break;
    }
  }

  void _syncSolo() {
    stage.solo(_editingPaths.map((path) => path.stageItem));
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
    cancelDebounce(_syncSolo);
    file.core.removeDelegate(this);
    stage.soloListenable.removeListener(_soloChanged);
    file.removeActionHandler(_handleAction);
  }
}
