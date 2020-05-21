import 'dart:ui';

import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/shapes/cubic_vertex.dart';
import 'package:rive_editor/rive/stage/items/stage_vertex.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';

/// Stage representation of a control point (in/out) for a cubic vertex.
abstract class StageControlVertex extends StageVertex<CubicVertex> {
  /// The mirrored/detached/asymmetric control point on the other side of the
  /// main vertex.
  StageControlVertex sibling;

  @override
  void drawPoint(Canvas canvas, Rect rect, Paint stroke, Paint fill) {
    canvas.drawRect(rect, stroke);
    canvas.drawRect(rect, fill);
  }

  @override
  double get radiusScale => 1;

  @override
  Mat2D get worldTransform => component.path.worldTransform;

  @override
  StageItem get soloParent => component.path.stageItem;
}

/// Concrete stage control point for the in handle.
class StageControlIn extends StageControlVertex {
  @override
  Vec2D get translation => component.inPoint;

  @override
  set translation(Vec2D value) => component.inPoint = value;

  @override
  set worldTranslation(Vec2D value) {
    final origin = component.artboard.originWorld;
    value[0] -= origin[0];
    value[1] -= origin[1];

    component.inPoint = Vec2D.transformMat2D(
        Vec2D(), value, component.path.inverseWorldTransform);
  }
}

/// Concrete stage control point for the out handle.
class StageControlOut extends StageControlVertex {
  @override
  Vec2D get translation => component.outPoint;

  @override
  set translation(Vec2D value) => component.outPoint = value;

  @override
  set worldTranslation(Vec2D value) {
    final origin = component.artboard.originWorld;
    value[0] -= origin[0];
    value[1] -= origin[1];
    component.outPoint = Vec2D.transformMat2D(
        Vec2D(), value, component.path.inverseWorldTransform);
  }
}

class StagePathControlLine extends StageItem<CubicVertex> {
  final StageVertex vertex;
  final StageVertex control;
  final Paint linePaint = Paint()..color = const Color(0x80FFFFFF);

  StagePathControlLine(this.vertex, this.control);

  @override
  bool get isSelectable => false;

  @override
  AABB get aabb => AABB.fromPoints([
        vertex.worldTranslation,
        control.worldTranslation,
      ]);

  @override
  void draw(Canvas canvas) {
    var inWorld = vertex.worldTranslation;
    var outWorld = control.worldTranslation;
    canvas.drawLine(Offset(inWorld[0], inWorld[1]),
        Offset(outWorld[0], outWorld[1]), linePaint);
  }

  void boundsChanged() => stage?.updateBounds(this);
}
