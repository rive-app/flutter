import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:core/debounce.dart';
import 'package:flutter/rendering.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/rive/stage/tools/clickable_tool.dart';
import 'package:rive_editor/rive/stage/tools/late_draw_stage_tool.dart';
import 'package:rive_editor/rive/stage/tools/moveable_tool.dart';
import 'package:rive_editor/rive/stage/tools/stage_tool.dart';
import 'package:rive_editor/rive/stage/tools/stage_tool_tip.dart';
import 'package:rive_editor/widgets/common/converters/hex_value_converter.dart';

typedef PickColor = void Function(Color);

/// A tool that allows the user to zoom into the stage and pick the color from a
/// specific pixel.
class ColorLoupeTool extends StageTool
    with LateDrawStageTool, MoveableTool, ClickableTool {
  final _whiteStroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..color = const Color(0xFFFFFFFF);

  final StageToolTip _tip = StageToolTip();

  Color _currentColor = const Color(0xFF000000);
  PickColor pickColor;
  StageTool _previousTool;

  ui.Image _rasterImage;
  ByteData _rasterPixels;
  @override
  String get icon => 'none';
  ui.Image get rasterImage => _rasterImage;

  ByteData get rasterPixels => _rasterPixels;

  @override
  void draw(ui.Canvas canvas) {
    // Whenever the stage draws, update the color buffer.
    debounce(_updateColorBuffer);
  }

  Future<void> _updateColorBuffer() async {
    if (stage.delegate == null) {
      return;
    }
    _rasterImage = await stage.delegate.rasterize();
    stage.lateDrawDelegate?.markNeedsPaint();
    _rasterPixels = await _rasterImage.toByteData();
  }

  @override
  bool updateMove(Vec2D worldMouse) {
    super.updateMove(worldMouse);

    // We override updateMove in order to specifically return false so that the
    // stage doesn't redraw/advance (unless it needs to for some external, to
    // us, reason). Because the stage doesn't redraw, the lateDraw view won't
    // either. This tool is special in that it wants to optimize the stage not
    // re-drawing, but does need the lateView to redraw so we can show our color
    // loupe. So we specifically let the late view know it needs to redraw here.

    // We need to let the late delegate know it needs to update.
    stage.lateDrawDelegate.markNeedsPaint();

    // We don't really manipulate content so don't update after we move, also
    // tries to keep the stage from redrawing (which causes us to re-rasterize
    // the view).
    return false;

    // P.S. one good way to check things are working right is to print someting
    // in the draw and lateDraw methods. You should see lots of lateDraw calls
    // and almost none (or very few) of the draw.
  }

  @override
  bool activate(Stage stage) {
    _previousTool = stage.tool;

    if (!super.activate(stage)) {
      return false;
    }
    stage.file.addActionHandler(_handleAction);
    return true;
  }

  bool _handleAction(ShortcutAction action) {
    switch (action) {
      case ShortcutAction.cancel:
        pickColor = null;

        // activate old tool
        stage.tool = _previousTool;
        return true;
      default:
        return false;
    }
  }

  @override
  void lateDraw(PaintingContext context, ui.Offset offset, Size viewSize) {
    var canvas = context.canvas;

    if (_rasterImage == null) {
      return;
    }

    var localMouse = stage.localMouse;
    var mx = (offset.dx + localMouse.dx).roundToDouble();
    var my = (offset.dy + localMouse.dy).roundToDouble();
    canvas.save();
    canvas.clipRect(offset & viewSize);

    var loupeSize = const Size(150, 150);
    var loupeOffset =
        Offset(mx - loupeSize.width / 2, my - loupeSize.height / 2);
    var loupeScale = 10.0;
    Rect clip = loupeOffset & loupeSize;
    canvas.save();
    canvas.translate(0, 50);
    canvas.drawOval(
        clip,
        Paint()
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50)
          ..color = const Color(0x66000000));
    canvas.translate(0, -50);
    canvas.clipRRect(
        RRect.fromRectAndRadius(clip, Radius.circular(loupeSize.width / 2)));

    canvas.save();
    canvas.translate(
      (-(mx + 0.5) * loupeScale + loupeOffset.dx + loupeSize.width / 2)
          .roundToDouble(),
      (-(my + 0.5) * loupeScale + loupeOffset.dy + loupeSize.height / 2)
          .roundToDouble(),
    );
    canvas.scale(loupeScale);
    canvas.drawImage(
      _rasterImage,
      offset,
      Paint()
        ..color = const Color(0xFFFFFFFF)
        ..isAntiAlias = false,
    );
    canvas.restore();

    canvas.saveLayer(
        loupeOffset & loupeSize, Paint()..color = const Color(0x40FFFFFF));
    var linePaint = Paint()..color = const Color(0xFF000000);
    canvas.save();
    canvas.translate(loupeOffset.dx + 0.5, loupeOffset.dy + 0.5);
    int numLinesX = (loupeSize.width / loupeScale).ceil();
    for (int i = 0; i < numLinesX; i++) {
      canvas.drawLine(const Offset(0, 0), Offset(0, loupeSize.height),
          linePaint..strokeWidth = 1);
      canvas.translate(loupeScale, 0);
    }
    canvas.restore();

    canvas.save();
    canvas.translate(loupeOffset.dx + 0.5, loupeOffset.dy + 0.5);
    int numLinesY = (loupeSize.height / loupeScale).ceil();
    for (int i = 0; i < numLinesY; i++) {
      canvas.drawLine(const Offset(0, 0), Offset(loupeSize.width, 0),
          linePaint..strokeWidth = 1);
      canvas.translate(0, loupeScale);
    }
    canvas.restore();
    canvas.restore();
    canvas.restore();
    canvas.drawRect(
      ((loupeOffset +
                  Offset(loupeSize.width / 2 - loupeScale / 2,
                      loupeSize.height / 2 - loupeScale / 2)) &
              Size(loupeScale, loupeScale))
          .inflate(0.5),
      _whiteStroke,
    );
    canvas.drawOval(
      clip.inflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = const Color(0x40000000),
    );
    canvas.drawOval(clip, _whiteStroke);
    canvas.restore();
    if (_rasterPixels != null) {
      var lmx = localMouse.dx.round();
      var lmy = localMouse.dy.round();
      var idx = (lmy.round().clamp(0, rasterImage.height - 1).toInt() *
                  rasterImage.width +
              lmx.round().clamp(0, rasterImage.width - 1).toInt()) *
          4;
      int r = _rasterPixels.getUint8(idx);
      int g = _rasterPixels.getUint8(idx + 1);
      int b = _rasterPixels.getUint8(idx + 2);
      _currentColor = Color.fromARGB(255, r, g, b);

      _tip.text =
          '#${HexValueConverter.instance.toDisplayValue(HSVColor.fromColor(_currentColor))}';

      _tip.paint(
          canvas,
          Offset(mx - _tip.paragraphSize.width / 2 - StageToolTip.padding.width,
              my + StageToolTip.padding.height + 20));
    }
  }

  static final ColorLoupeTool instance = ColorLoupeTool();

  @override
  void onClick(Artboard activeArtboard, Vec2D worldMouse) {
    var pick = pickColor;
    pickColor = null;
    pick?.call(_currentColor);

    // activate old tool
    stage.tool = _previousTool;
  }
}
