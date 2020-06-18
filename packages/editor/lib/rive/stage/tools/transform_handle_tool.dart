import 'dart:ui';

import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/node.dart';
import 'package:rive_editor/rive/selection_context.dart';
import 'package:rive_editor/rive/stage/items/stage_rotation_handle.dart';
import 'package:rive_editor/rive/stage/items/stage_scale_handle.dart';
import 'package:rive_editor/rive/stage/items/stage_translation_handle.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/draggable_tool.dart';
import 'package:rive_editor/rive/stage/tools/stage_tool.dart';
import 'package:rive_editor/rive/stage/tools/transformers/stage_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transforming_tool.dart';
import 'package:rive_editor/selectable_item.dart';

abstract class TransformHandleTool extends StageTool
    with DraggableTool, TransformingTool {
  final _translateX = StageTranslationHandle(
    color: const Color(0xFF16E7B3),
    direction: Vec2D.fromValues(1, 0),
  );
  final _translateY = StageTranslationHandle(
    color: const Color(0xFFFF929F),
    direction: Vec2D.fromValues(0, -1),
  );

  final _rotation = StageRotationHandle(showAxis: false);

  final _scaleX = StageScaleHandle(
    color: const Color(0xFF16E7B3),
    direction: Vec2D.fromValues(1, 0),
  );
  final _scaleY = StageScaleHandle(
    color: const Color(0xFFFF929F),
    direction: Vec2D.fromValues(0, -1),
  );

  SelectionContext<SelectableItem> _selectionContext;
  Set<Node> _nodes = {};

  @override
  bool activate(Stage stage) {
    if (!super.activate(stage)) {
      return false;
    }
    _selectionContext = stage.file.selection;
    _selectionContext.addListener(_selectionChanged);
    stage.addSelectionHandler(_handleStageSelection);
    _selectionChanged();
    return true;
  }

  TransformerMaker _transformingHandle;
  bool get isTransforming => _transformingHandle != null;

  bool _handleStageSelection(StageItem item) {
    if (item is TransformerMaker) {
      _transformingHandle = item as TransformerMaker;
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
    _setSelection({});
  }

  bool get hasTransformSelection =>
      _translateX.stage != null ||
      _translateY.stage != null ||
      _rotation != null ||
      _scaleX.stage != null ||
      _scaleY.stage != null;

  void _selectionChanged() {
    var nodes = <Node>{};
    for (final item in _selectionContext.items) {
      if (item is StageItem && item.component is Node) {
        nodes.add(item.component as Node);
      }
    }
    _setSelection(nodes);
  }

  void _setSelection(Set<Node> nodes) {
    // TODO: check equals with IterableEquals to avoid recompute?
    for (final node in _nodes) {
      node.worldTransformChanged.removeListener(_selectionChanged);
    }

    _nodes = nodes;
    if (nodes.isEmpty) {
      stage.removeItem(_translateX);
      stage.removeItem(_translateY);
      stage.removeItem(_rotation);
      stage.removeItem(_scaleX);
      stage.removeItem(_scaleY);
    } else {
      stage.addItem(_translateX);
      stage.addItem(_translateY);
      stage.addItem(_rotation);
      stage.addItem(_scaleX);
      stage.addItem(_scaleY);

      _computeHandleTransform();
    }

    for (final node in nodes) {
      node.worldTransformChanged.addListener(_selectionTransformChanged);
    }
  }

  void _computeHandleTransform() {
    if (_nodes.isEmpty) {
      return;
    }
    var first = _nodes.first;
    _translateX.transform = first.worldTransform;
    _translateY.transform = first.worldTransform;
    _rotation.transform = first.worldTransform;
    _scaleX.transform = first.worldTransform;
    _scaleY.transform = first.worldTransform;
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
