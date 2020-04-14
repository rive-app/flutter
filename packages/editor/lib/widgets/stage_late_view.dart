import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/rive/stage/tools/late_draw_stage_tool.dart';

/// Rendering delegate for the stage that draws after all other stage content.
class StageLateView extends LeafRenderObjectWidget {
  final Stage stage;

  const StageLateView({this.stage});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _LoupeRenderObject()..stage = stage;
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant _LoupeRenderObject renderObject) {
    renderObject.stage = stage;
  }

  @override
  void didUnmountRenderObject(covariant _LoupeRenderObject renderObject) {
    renderObject.dispose();
  }
}

class _LoupeRenderObject extends RenderBox implements LateDrawViewDelegate {
  LateDrawStageTool _tool;

  @override
  LateDrawStageTool get tool => _tool;

  @override
  set tool(LateDrawStageTool value) {
    if (_tool == value) {
      return;
    }
    _tool = value;
    markNeedsPaint();
  }

  Stage _stage;
  Stage get stage => _stage;
  set stage(Stage value) {
    if (_stage == value) {
      return;
    }
    _stage = value;
    stage.lateDrawDelegate = this;
    markNeedsPaint();
  }

  @override
  bool get sizedByParent => true;

  @override
  void performResize() {
    size = constraints.biggest;
  }

  @override
  void performLayout() {
    _stage.setViewport(size.width, size.height);
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      _tool?.lateDraw(context, offset, size);

  void dispose() {
    _stage?.lateDrawDelegate = null;
  }

  // @override
  // bool get isRepaintBoundary => false;
}
