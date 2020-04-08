import 'dart:ui';

import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/shapes/paint/radial_gradient.dart' as core;
import 'package:rive_editor/rive/stage/items/stage_gradient.dart';

/// Concrete radial version of the stage gradient.
class StageRadialGradient extends StageGradient<core.RadialGradient> {
  static Paint line = Paint()
    ..style = PaintingStyle.stroke
    ..color = const Color(0x80FFFFFF);

  @override
  void draw(Canvas canvas) {
    super.draw(canvas);
    // StageGradient.border.strokeWidth = 3 / stage.viewZoom;
    line.strokeWidth = 1 / stage.viewZoom;

    var radius = Vec2D.length(Vec2D.subtract(Vec2D(), end, start));
    canvas.drawCircle(startOffset, radius, StageGradient.border);
    canvas.drawCircle(startOffset, radius, line);
  }
}
