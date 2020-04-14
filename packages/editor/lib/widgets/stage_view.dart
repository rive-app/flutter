import 'dart:ui' as ui;
import 'package:cursor/cursor_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/rive/stage/stage.dart';

/// Draws a path with custom paint and a nudge property.
class StageView extends LeafRenderObjectWidget {
  /// The Rive context.
  final OpenFileContext file;
  final Stage stage;
  final Cursor customCursor;
  const StageView({
    this.file,
    this.stage,
    this.customCursor,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _StageViewRenderObject()
      ..file = file
      ..stage = stage
      ..customCursor = customCursor;
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant _StageViewRenderObject renderObject) {
    renderObject
      ..file = file
      ..stage = stage
      ..customCursor = customCursor;
  }

  @override
  void didUnmountRenderObject(covariant _StageViewRenderObject renderObject) {
    renderObject.dispose();
  }
}

class _StageViewRenderObject extends RenderBox implements StageDelegate {
  // Just a way for the stage to request a change of cursor.
  @override
  Cursor customCursor;

  OpenFileContext _file;

  OpenFileContext get file => _file;
  set file(OpenFileContext value) {
    if (_file == value) {
      return;
    }
    _file = value;
    _file?.stage?.delegateTo(this);
    markNeedsPaint();
  }

  Stage _stage;
  Stage get stage => _stage;
  set stage(Stage value) {
    if (_stage == value) {
      return;
    }
    _stage = value;
    stage.delegateTo(this);
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

  @override
  bool get isRepaintBoundary => true;

  @override
  Future<ui.Image> rasterize() =>
      (layer as OffsetLayer).toImage(Offset.zero & size); //, pixelRatio = 1 });
}
