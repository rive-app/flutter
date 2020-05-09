import 'dart:ui';

import 'package:rive_core/artboard.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_editor/rive/stage/tools/stage_tool.dart';

abstract class PenTool extends StageTool {
  @override
  void draw(Canvas canvas) {
    _paintVertex(canvas, stage.localMouse);
  }

  void _paintVertex(Canvas canvas, Offset offset) {
    // Draw twice: once for the background stroke, and a second time for
    // the foreground
    canvas.drawCircle(offset, 4.5, Paint()..color = const Color(0x19000000));
    canvas.drawCircle(offset, 3.5, Paint()..color = const Color(0xFFFFFFFF));
  }

  @override
  bool mouseMove(Artboard activeArtboard, Vec2D worldMouse) {
    // We want to continuously advance so we repaint the vertex position.
    return true;
  }

  @override
  String get icon => 'tool-pen';
}
