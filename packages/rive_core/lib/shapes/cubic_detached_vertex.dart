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
    this.inPoint = Vec2D.fromValues(inX ?? inPoint[0], inY ?? inPoint[1]);
    this.outPoint = Vec2D.fromValues(outX ?? outPoint[0], outY ?? outPoint[1]);
  }

  @override
  Vec2D get outPoint => _outPoint ??= Vec2D.add(
      Vec2D(),
      translation,
      Vec2D.fromValues(
          cos(outRotation) * outDistance, sin(outRotation) * outDistance));

  @override
  set outPoint(Vec2D value) {
    // -> editor-only
    var lastRotation = outRotation;
    var diffOut = Vec2D.fromValues(value[0] - x, value[1] - y);
    outDistance = Vec2D.length(diffOut);
    outRotation = atan2(diffOut[1], diffOut[0]);
    // <- editor-only
    _outPoint = Vec2D.clone(value);

    // -> editor-only
    if (accumulateAngle) {
      outRotation = lastRotation +
          atan2(
              sin(outRotation - lastRotation), cos(outRotation - lastRotation));
    }
    // <- editor-only
  }

  @override
  Vec2D get inPoint => _inPoint ??= Vec2D.add(
      Vec2D(),
      translation,
      Vec2D.fromValues(
          cos(inRotation) * inDistance, sin(inRotation) * inDistance));

  @override
  set inPoint(Vec2D value) {
    // -> editor-only
    var lastRotation = inRotation;
    var diffIn = Vec2D.fromValues(value[0] - x, value[1] - y);
    inDistance = Vec2D.length(diffIn);
    inRotation = atan2(diffIn[1], diffIn[0]);
    // <- editor-only
    _inPoint = Vec2D.clone(value);

    // -> editor-only
    if (accumulateAngle) {
      inRotation = lastRotation +
          atan2(sin(inRotation - lastRotation), cos(inRotation - lastRotation));
    }
    // <- editor-only
  }

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

  // -> editor-only
  @override
  bool exports(int propertyKey) {
    switch (propertyKey) {
      case CubicDetachedVertexBase.inRotationPropertyKey:
      case CubicDetachedVertexBase.inDistancePropertyKey:
        return inDistance.abs() > 0.001;
      case CubicDetachedVertexBase.outRotationPropertyKey:
      case CubicDetachedVertexBase.outDistancePropertyKey:
        return outDistance.abs() > 0.001;
    }
    return super.exports(propertyKey);
  }
  // <- editor-only
}
