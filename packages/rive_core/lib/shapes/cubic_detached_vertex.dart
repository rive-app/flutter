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
    _inPoint = Vec2D.fromValues(inX ?? inPoint[0], inY ?? inPoint[1]);
    _outPoint = Vec2D.fromValues(outX ?? outPoint[0], outY ?? outPoint[1]);
  }

  @override
  Vec2D get outPoint {
    return _outPoint ??= Vec2D.add(
        Vec2D(),
        translation,
        Vec2D.fromValues(
            cos(outRotation) * outDistance, sin(outRotation) * outDistance));
  }

  // -> editor-only
  @override
  set outPoint(Vec2D value) {
    var lastRotation = outRotation;
    var diffOut = Vec2D.fromValues(value[0] - x, value[1] - y);
    outDistance = Vec2D.length(diffOut);
    outRotation = atan2(diffOut[1], diffOut[0]);
    _outPoint = Vec2D.clone(value);

    if (accumulateAngle) {
      outRotation = lastRotation +
          atan2(
              sin(outRotation - lastRotation), cos(outRotation - lastRotation));
    }
  }
  // <- editor-only

  @override
  Vec2D get inPoint {
    return _inPoint ??= Vec2D.add(
        Vec2D(),
        translation,
        Vec2D.fromValues(
            cos(inRotation) * inDistance, sin(inRotation) * inDistance));
  }

  // -> editor-only
  @override
  set inPoint(Vec2D value) {
    var lastRotation = inRotation;
    var diffIn = Vec2D.fromValues(value[0] - x, value[1] - y);
    inDistance = Vec2D.length(diffIn);
    inRotation = atan2(diffIn[1], diffIn[0]);
    _inPoint = Vec2D.clone(value);

    if (accumulateAngle) {
      inRotation = lastRotation +
          atan2(sin(inRotation - lastRotation), cos(inRotation - lastRotation));
    }
  }
  // <- editor-only

  @override
  String toString() {
    return 'in ${inPoint[0]}, ${inPoint[1]} | ${translation.toString()} '
        '| out ${outPoint[0]}, ${outPoint[1]}';
  }

  @override
  void xChanged(double from, double to) {
    super.xChanged(from, to);
    _outPoint = _inPoint = null;
  }

  @override
  void yChanged(double from, double to) {
    super.xChanged(from, to);
    _outPoint = _inPoint = null;
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
