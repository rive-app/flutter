import 'dart:ui';

import 'package:rive_core/bounds_delegate.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/shapes/paint/linear_gradient.dart' as core;
import 'package:rive_editor/rive/stage/stage_item.dart';

class StageLinearGradient extends StageItem<core.LinearGradient>
    with BoundsDelegate {
  static Paint border = Paint()
    ..style = PaintingStyle.stroke
    ..color = const Color(0x40000000);

  static Paint line = Paint()
    ..style = PaintingStyle.stroke
    ..color = const Color(0xFFFFFFFF);

  AABB _aabb;

  @override
  AABB get aabb => _aabb;

  @override
  bool initialize(core.LinearGradient object) {
    if (!super.initialize(object)) {
      return false;
    }
    _update();
    return true;
  }

  Offset _start;
  Offset _end;

  void _update() {
    // We want the start and end in world transform space, regardless of how the
    // shape paints.
    var world = Mat2D.translate(
        Mat2D(),
        component.shapePaintContainer.worldTransform,
        component.artboard.originWorld);

    var start = Vec2D.transformMat2D(Vec2D(), component.start, world);
    var end = Vec2D.transformMat2D(Vec2D(), component.end, world);

    // Compute world transform of start/end points expand by our stroke
    // dimensions (make sure the bounding box is at least that wide/high).
    _aabb = AABB.fromPoints([start, end], expand: 2);
    _start = Offset(start[0], start[1]);
    _end = Offset(end[0], end[1]);

    stage?.updateBounds(this);
  }

  @override
  void boundsChanged() => _update();

  @override
  void draw(Canvas canvas) {
    border.strokeWidth = 3 / stage.viewZoom;
    line.strokeWidth = 1 / stage.viewZoom;

    canvas.drawLine(_start, _end, border);
    canvas.drawLine(_start, _end, line);
  }
}
