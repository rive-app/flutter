import 'dart:ui';

import 'package:rive_core/math/vec2d.dart';
import 'package:rive_editor/rive/selection_context.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/rive/stage/items/stage_handle.dart';
import 'package:rive_editor/rive/stage/items/stage_rotation_handle.dart';
import 'package:rive_editor/rive/stage/items/stage_scale_handle.dart';
import 'package:rive_editor/rive/stage/items/stage_translation_handle.dart';
import 'package:rive_editor/rive/stage/items/stage_transformable.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/draggable_tool.dart';
import 'package:rive_editor/rive/stage/tools/stage_tool.dart';
import 'package:rive_editor/rive/stage/tools/transformers/stage_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transforming_tool.dart';
import 'package:rive_editor/selectable_item.dart';
import 'package:utilities/restorer.dart';

/// An abstraction allowing a StageItem to mutate the selection prior to
/// initializing transformers based on some selected handle. For example, a
/// StageJoint includes the parent bone in the transform selection when the Y
/// translation handle is selected.
// ignore: one_member_abstracts
abstract class TransfomHandleSelectionMutator {
  void mutateTransformSelection(StageHandle handle, List<StageItem> selection);
}

abstract class TransformHandleTool extends StageTool
    with DraggableTool, TransformingTool {
  final StageTranslationHandle _translateX;
  final StageTranslationHandle _translateY;
  final StageRotationHandle _rotation;
  final StageScaleHandle _scaleX;
  final StageScaleHandle _scaleY;

  TransformHandleTool({
    bool hasTranslationHandles = true,
    bool hasRotationHandle = true,
    bool hasScaleHandles = true,
  })  : _translateX = hasTranslationHandles
            ? StageTranslationHandle(
                color: const Color(0xFF16E7B3),
                direction: Vec2D.fromValues(1, 0),
                transformType: TransformFlags.x,
              )
            : null,
        _translateY = hasTranslationHandles
            ? StageTranslationHandle(
                color: const Color(0xFFFF929F),
                direction: Vec2D.fromValues(0, -1),
                transformType: TransformFlags.y,
              )
            : null,
        _rotation =
            hasRotationHandle ? StageRotationHandle(showAxis: false) : null,
        _scaleX = hasScaleHandles
            ? StageScaleHandle(
                color: const Color(0xFF16E7B3),
                direction: Vec2D.fromValues(1, 0),
                transformType: TransformFlags.scaleX,
              )
            : null,
        _scaleY = hasScaleHandles
            ? StageScaleHandle(
                color: const Color(0xFFFF929F),
                direction: Vec2D.fromValues(0, -1),
                transformType: TransformFlags.scaleY,
              )
            : null;

  bool get showRotationHandle => true;
  bool get showTranslationHandle => true;
  bool get showScaleHandle => true;

  SelectionContext<SelectableItem> _selectionContext;
  StageTransformable _transformable;

  /// Tracks hidden handles that should be restored when transformers complete
  Restorer restoreHandles;
  Restorer _selectionHandlerRestorer;

  @override
  bool activate(Stage stage) {
    if (!super.activate(stage)) {
      return false;
    }
    _selectionContext = stage.file.selection;
    _selectionContext.addListener(_selectionChanged);
    _selectionHandlerRestorer =
        stage.addSelectionHandler(_handleStageSelection);
    // Sync the selection whenver the show handles value changes.
    stage.isHidingHandlesChanged.addListener(_selectionChanged);
    _selectionChanged();
    return true;
  }

  @override
  void startTransformers(
    covariant Iterable<StageItem> selection,
    Vec2D worldMouse,
  ) {
    Iterable<StageItem> transformSelection = selection;

    // If a handle was hit, check if there are any StageItems that may want to
    // mutate the transform selection.
    if (_transformingHandle != null) {
      var mutators = selection.whereType<TransfomHandleSelectionMutator>();
      if (mutators.isNotEmpty) {
        // The selection handle may want to mutate selection...
        var mutatedSelection =
            transformSelection = selection.toList(growable: true);
        for (final mutator in mutators) {
          mutator.mutateTransformSelection(
              _transformingHandle, mutatedSelection);
        }
      }
    } else if (!ShortcutAction.freezeToggle.value) {
      restoreHandles = stage.hideHandles();
    }

    // Call the super before messing with hiding things
    super.startTransformers(transformSelection, worldMouse);
  }

  @override
  void completeTransformers() {
    super.completeTransformers();
    // Restore handles if necessary
    if (restoreHandles != null) {
      restoreHandles.restore();
      restoreHandles = null;
    }
  }

  StageHandle _transformingHandle;
  bool get isTransforming => _transformingHandle != null;

  bool _handleStageSelection(StageItem item) {
    if (item is StageHandle) {
      _transformingHandle = item;
      return true;
    }
    return false;
  }

  @override
  List<StageTransformer> get transformers =>
      _transformingHandle?.makeTransformers() ?? super.transformers;

  @override
  void deactivate() {
    super.deactivate();
    _selectionContext.removeListener(_selectionChanged);
    _selectionHandlerRestorer?.restore();
    stage.isHidingHandlesChanged.removeListener(_selectionChanged);
    _setSelection({});
  }

  void _selectionChanged() {
    _setSelection(
        _selectionContext.items.whereType<StageTransformable>().toSet());
  }

  void _addHandle(StageHandle handle) {
    if (handle == null ||
        (_transformable.transformFlags & handle.transformType) !=
            handle.transformType) {
      _removeHandle(handle);
      return;
    }
    stage.addItem(handle);
  }

  void _removeHandle(StageHandle handle) {
    if (handle == null) {
      return;
    }
    stage.removeItem(handle);
  }

  void _setSelection(Set<StageTransformable> transformables) {
    _transformable?.worldTransformChanged
        ?.removeListener(_selectionTransformChanged);

    if (transformables.isEmpty || stage.isHidingHandles) {
      _transformable = null;
      _removeHandle(_translateX);
      _removeHandle(_translateY);
      _removeHandle(_rotation);
      _removeHandle(_scaleX);
      _removeHandle(_scaleY);
    } else {
      _transformable = transformables.first;
      _addHandle(_translateX);
      _addHandle(_translateY);
      _addHandle(_rotation);
      _addHandle(_scaleX);
      _addHandle(_scaleY);

      _computeHandleTransform();
    }

    _transformable?.worldTransformChanged
        ?.addListener(_selectionTransformChanged);
  }

  void _computeHandleTransform() {
    if (_transformable == null) {
      return;
    }

    var transform = _transformable.worldTransform;
    var renderTransform = _transformable.renderTransform;
    _translateX?.setTransform(transform, renderTransform);
    _translateY?.setTransform(transform, renderTransform);
    _rotation?.setTransform(transform, renderTransform);
    _scaleX?.setTransform(transform, renderTransform);
    _scaleY?.setTransform(transform, renderTransform);
  }

  void _selectionTransformChanged() {
    _computeHandleTransform();
  }

  @override
  void endDrag() {
    _transformingHandle = null;
  }

  @override
  void updateDrag(Vec2D worldMouse) {}
}
