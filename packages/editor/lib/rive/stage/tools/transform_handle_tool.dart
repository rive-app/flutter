import 'dart:collection';
import 'dart:ui';

import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/node.dart';
import 'package:rive_editor/rive/selection_context.dart';
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
  final StageTranslationHandle _translateX = StageTranslationHandle(
      color: const Color(0xFF16E7B3), direction: Vec2D.fromValues(1, 0));
  final StageTranslationHandle _translateY = StageTranslationHandle(
      color: const Color(0xFFFF929F), direction: Vec2D.fromValues(0, -1));

  SelectionContext<SelectableItem> _selectionContext;
  HashSet<Node> _nodes = HashSet<Node>();

  @override
  bool activate(Stage stage) {
    if (!super.activate(stage)) {
      return false;
    }
    _selectionContext = stage.file.selection;
    _selectionContext.addListener(_selectionChanged);
    stage.addSelectionHandler(_handleStageSelection);
    return true;
  }

  TransformerMaker _transformingHandle;
  bool get isTransforming => _transformingHandle != null;

  bool _handleStageSelection(StageItem item) {
    if (item is StageTranslationHandle) {
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
    _setSelection(HashSet<Node>());
  }

  bool get hasTransformSelection =>
      _translateX.stage != null || _translateY.stage != null;

  void _selectionChanged() {
    var nodes = HashSet<Node>();
    for (final item in _selectionContext.items) {
      if (item is StageItem && item.component is Node) {
        nodes.add(item.component as Node);
      }
    }
    _setSelection(nodes);
  }

  void _setSelection(HashSet<Node> nodes) {
    // TODO: check equals with IterableEquals to avoid recompute?
    for (final node in _nodes) {
      node.worldTransformChanged.removeListener(_selectionChanged);
    }

    _nodes = nodes;
    if (nodes.isEmpty) {
      stage.removeItem(_translateX);
      stage.removeItem(_translateY);
    } else {
      stage.addItem(_translateX);
      stage.addItem(_translateY);

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
