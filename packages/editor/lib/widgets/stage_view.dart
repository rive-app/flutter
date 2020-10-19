import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/rive/stage/stage_context_menu_launcher.dart';

/// Draws the stage and marshals events for the stage that the UI is interested
/// in (like showing popup menus).
class StageView extends StatefulWidget {
  final OpenFileContext file;
  final Stage stage;
  final void Function(StageContextMenuDetails) showContextMenu;

  const StageView({
    @required this.file,
    @required this.stage,
    this.showContextMenu,
    Key key,
  }) : super(key: key);

  @override
  _StageViewState createState() => _StageViewState();
}

class _StageViewState extends State<StageView> {
  @override
  void initState() {
    widget.stage.showContextMenu.addListener(_showContextMenu);
    super.initState();
  }

  @override
  void dispose() {
    widget.stage.showContextMenu.removeListener(_showContextMenu);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant StageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stage != widget.stage) {
      oldWidget.stage?.showContextMenu?.removeListener(_showContextMenu);
      widget.stage?.showContextMenu?.addListener(_showContextMenu);
    }
  }

  void _showContextMenu(StageContextMenuDetails contextMenuDetails) {
    widget.showContextMenu?.call(contextMenuDetails);
  }

  @override
  Widget build(BuildContext context) {
    return StageViewRenderer(file: widget.file, stage: widget.stage);
  }
}

/// Widget that manages the lifecycle of the render object for the stage.
class StageViewRenderer extends LeafRenderObjectWidget {
  /// The Rive context.
  final OpenFileContext file;
  final Stage stage;
  const StageViewRenderer({
    this.file,
    this.stage,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _StageViewRenderObject()
      ..file = file
      ..stage = stage
      ..context = context;
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant _StageViewRenderObject renderObject) {
    renderObject
      ..file = file
      ..stage = stage
      ..context = context;
  }

  @override
  void didUnmountRenderObject(covariant _StageViewRenderObject renderObject) {
    renderObject.dispose();
  }
}

class _StageViewRenderObject extends RenderBox implements StageDelegate {
  // Just a way for the stage to request a change of cursor.
  @override
  BuildContext context;

  OpenFileContext _file;

  OpenFileContext get file => _file;
  set file(OpenFileContext value) {
    if (_file == value) {
      return;
    }
    _file?.stage?.clearDelegate(this);
    _file = value;
    _file?.stage?.delegateTo(this);
    markNeedsLayout();
  }

  Stage _stage;
  Stage get stage => _stage;
  set stage(Stage value) {
    if (_stage == value) {
      return;
    }
    _stage?.clearDelegate(this);
    _stage = value;
    stage.delegateTo(this);
    markNeedsLayout();
  }

  @override
  bool get sizedByParent => true;

  @override
  void performResize() {
    size = constraints.biggest;
  }

  @override
  void performLayout() {
    // Debounce changing the dimensions as this can set value notifiers that
    // will trigger a rebuild during this rebuild.
    _stage.debounce(() {
      stage.setViewport(size.width, size.height);
    });
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
