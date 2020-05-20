import 'dart:ui';

import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/shapes/cubic_vertex.dart';
import 'package:rive_editor/rive/stage/items/stage_vertex.dart';

/// Stage representation of a control point (in/out) for a cubic vertex.
abstract class StageControlVertex extends StageVertex<CubicVertex> {
  @override
  void drawPoint(Canvas canvas, Rect rect, Paint stroke, Paint fill) {
    canvas.drawRect(rect, stroke);
    canvas.drawRect(rect, fill);
  }

  @override
  double get radiusScale => 1;

  @override
  Mat2D get worldTransform => component.path.worldTransform;
}

/// Concrete stage control point for the in handle.
class StageControlIn extends StageControlVertex {
  @override
  Vec2D get translation => component.inPoint;
}

/// Concrete stage control point for the out handle.
class StageControlOut extends StageControlVertex {
  @override
  Vec2D get translation => component.outPoint;
}
