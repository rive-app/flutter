import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/rive/stage/stage.dart';

/// Draws a path with custom paint and a nudge property.
class StageView extends LeafRenderObjectWidget {
  /// The Rive context.
  final OpenFileContext file;
  final Stage stage;

  const StageView({this.file, this.stage});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _StageViewRenderObject()
      ..file = file
      ..stage = stage;
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant _StageViewRenderObject renderObject) {
    renderObject
      ..file = file
      ..stage = stage;
  }

  @override
  void didUnmountRenderObject(covariant _StageViewRenderObject renderObject) {
    renderObject.dispose();
  }
}

class _StageViewRenderObject extends RenderBox implements StageDelegate {
  OpenFileContext _file;

  OpenFileContext get file => _file;
  set file(OpenFileContext value) {
    if (_file == value) {
      return;
    }
    _file = value;
    _file?.stage?.delegate(this);
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
    file = null;
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
