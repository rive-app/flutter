import 'dart:math';

import 'package:rive_core/component_dirt.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/src/generated/shapes/cubic_detached_vertex_base.dart';
export 'package:rive_core/src/generated/shapes/cubic_detached_vertex_base.dart';

class CubicDetachedVertex extends CubicDetachedVertexBase {
  Vec2D _inPoint;
  Vec2D _outPoint;

  CubicDetachedVertex();
  CubicDetachedVertex.fromValues({
    double x,
    double y,
    double inX,
    double inY,
    double outX,
    double outY,
    Vec2D inPoint,
    Vec2D outPoint,
  }) {
    this.x = x;
    this.y = y;

    var diffIn = Vec2D.fromValues(inX ?? inPoint[0] - x, inY ?? inPoint[1] - y);
    inDistance = Vec2D.length(diffIn);
    inRotation = atan2(diffIn[1], diffIn[0]);

    var diffOut =
        Vec2D.fromValues(outX ?? outPoint[0] - x, outY ?? outPoint[1] - y);
    outDistance = Vec2D.length(diffOut);
    outRotation = atan2(diffOut[1], diffOut[0]);
  }

  @override
  Vec2D get outPoint {
    return _outPoint ??= Vec2D.add(
        Vec2D(),
        translation,
        Vec2D.fromValues(
            cos(outRotation) * outDistance, sin(outRotation) * outDistance));
  }

  @override
  set outPoint(Vec2D value) {
    var diffOut = Vec2D.fromValues(value[0] - x, value[1] - y);
    outDistance = Vec2D.length(diffOut);
    outRotation = atan2(diffOut[1], diffOut[0]);
    _outPoint = Vec2D.clone(value);
  }

  @override
  Vec2D get inPoint {
    return _inPoint ??= Vec2D.add(
        Vec2D(),
        translation,
        Vec2D.fromValues(
            cos(inRotation) * -inDistance, sin(inRotation) * -inDistance));
  }

  @override
  set inPoint(Vec2D value) {
    var diffIn = Vec2D.fromValues(value[0] - x, value[1] - y);
    inDistance = Vec2D.length(diffIn);
    inRotation = atan2(diffIn[1], diffIn[0])+pi;
    _inPoint = Vec2D.clone(value);
  }

  @override
  String toString() {
    return 'in ${inPoint[0]}, ${inPoint[1]} | ${translation.toString()} '
        '| out ${outPoint[0]}, ${outPoint[1]}';
  }

  @override
  void inDistanceChanged(double from, double to) {
    addDirt(ComponentDirt.worldTransform);
    _inPoint = null;
    path?.markPathDirty();
  }

  @override
  void inRotationChanged(double from, double to) {
    addDirt(ComponentDirt.worldTransform);
    _inPoint = null;
    path?.markPathDirty();
  }

  @override
  void outDistanceChanged(double from, double to) {
    addDirt(ComponentDirt.worldTransform);
    _outPoint = null;
    path?.markPathDirty();
  }

  @override
  void outRotationChanged(double from, double to) {
    addDirt(ComponentDirt.worldTransform);
    _outPoint = null;
    path?.markPathDirty();
  }
}
