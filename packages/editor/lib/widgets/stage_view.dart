import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:rive_editor/rive/stage/stage.dart';

/// Draws a path with custom paint and a nudge property.
class StageView extends LeafRenderObjectWidget {
  /// The Rive context.
  final Rive rive;
  final Stage stage;

  const StageView({this.rive, this.stage});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _StageViewRenderObject()
      ..rive = rive
      ..stage = stage;
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant _StageViewRenderObject renderObject) {
    renderObject
      ..rive = rive
      ..stage = stage;
  }

  @override
  void didUnmountRenderObject(covariant _StageViewRenderObject renderObject) {
    renderObject.dispose();
  }
}

class _StageViewRenderObject extends RenderBox implements StageDelegate {
  Rive _rive;

  Rive get rive => _rive;
  set rive(Rive value) {
    if (_rive == value) {
      return;
    }
    _rive = value;
    _rive?.stage?.value?.delegate(this);
    markNeedsPaint();
  }

  Stage _stage;
  Stage get stage => _stage;
  set stage(Stage value) {
    if (_stage == value) {
      return;
    }
    _stage = value;
    stage.delegate(this);
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
    _stage.draw(context, offset, size);

  void dispose() {
    _stage?.clearDelegate(this);
    rive = null;
  }

  @override
  void stageNeedsAdvance() {
    // updatePlayState();
  }

  @override
  void stageNeedsRedraw() {
    markNeedsPaint();
  }
}
