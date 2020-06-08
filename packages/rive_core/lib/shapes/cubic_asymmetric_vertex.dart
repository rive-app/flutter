import 'dart:math';

import 'package:rive_core/component_dirt.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/src/generated/shapes/cubic_asymmetric_vertex_base.dart';
export 'package:rive_core/src/generated/shapes/cubic_asymmetric_vertex_base.dart';

class CubicAsymmetricVertex extends CubicAsymmetricVertexBase {
  Vec2D _inPoint;
  Vec2D _outPoint;
  @override
  Vec2D get outPoint {
    return _outPoint ??= Vec2D.add(Vec2D(), translation, Vec2D.fromValues(
        cos(rotation) * outDistance, sin(rotation) * outDistance));
  }

  @override
  set outPoint(Vec2D value) {
    var diffOut = Vec2D.fromValues(value[0] - x, value[1] - y);
    outDistance = Vec2D.length(diffOut);
    rotation = atan2(diffOut[1], diffOut[0]);
    _inPoint = Vec2D.clone(value);
  }

  @override
  Vec2D get inPoint {
    return _inPoint ??= Vec2D.add(Vec2D(), translation, Vec2D.fromValues(
        cos(rotation) * -inDistance, sin(rotation) * -inDistance));
  }

  @override
  set inPoint(Vec2D value) {
    var diffIn = Vec2D.fromValues(value[0] - x, value[1] - y);
    inDistance = Vec2D.length(diffIn);
    rotation = atan2(diffIn[1], diffIn[0]) + pi;
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
    _inPoint = _outPoint = null;
    path?.markPathDirty();
  }

  @override
  void outDistanceChanged(double from, double to) {
    addDirt(ComponentDirt.worldTransform);
    _inPoint = _outPoint = null;
    path?.markPathDirty();
  }

  @override
  void rotationChanged(double from, double to) {
    addDirt(ComponentDirt.worldTransform);
    _inPoint = _outPoint = null;
    path?.markPathDirty();
  }
}
