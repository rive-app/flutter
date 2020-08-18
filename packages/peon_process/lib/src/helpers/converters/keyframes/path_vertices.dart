import 'package:flutter/foundation.dart';
import 'package:peon_process/converters.dart';
import 'package:rive_core/animation/keyframe_double.dart';
import 'package:rive_core/animation/linear_animation.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/shapes/cubic_asymmetric_vertex.dart';
import 'package:rive_core/shapes/cubic_detached_vertex.dart';
import 'package:rive_core/shapes/cubic_mirrored_vertex.dart';
import 'package:rive_core/shapes/path_vertex.dart';
import 'package:rive_core/shapes/straight_vertex.dart';
///
/// The input value in this case is a JSON object containing:
/// - 'pos' that is the vertex translation in this keyframe
/// - 'radius' that is the corner radius (Straight vertices only)
/// - 'in'/'out' control points for the Bezier curves
/// (all vertex types, except Straight)
///
abstract class KeyFrameVertexConverter extends KeyFrameConverter {
  const KeyFrameVertexConverter(
      Map value, int interpolatorType, List interpolatorCurve)
      : super(value, interpolatorType, interpolatorCurve);

  factory KeyFrameVertexConverter.fromVertex(PathVertexBase vertex, Map data,
      int interpolatorType, List interpolatorCurve) {
    switch (vertex.runtimeType) {
      case StraightVertex:
        return KeyFrameStraightVertexConverter(
            data, interpolatorType, interpolatorCurve);
      case CubicMirroredVertex:
        return KeyFrameMirroredVertexConverter(
            data, interpolatorType, interpolatorCurve);
      case CubicDetachedVertex:
        return KeyFrameDetachedVertexConverter(
            data, interpolatorType, interpolatorCurve);
      case CubicAsymmetricVertex:
        return KeyFrameAsymmetricVertexConverter(
            data, interpolatorType, interpolatorCurve);
    }
    return null;
  }

  @override
  void convertKey(Component component, LinearAnimation animation, int frame) {
    if (component is! PathVertexBase) {
      throw StateError(
          'Cannot add vertex keyframes to ${component.runtimeType}');
    }
    final vertex = component as PathVertexBase;

    final pos = getValueProperty('pos') as List;
    final xValue = (pos[0] as num).toDouble();
    final yValue = (pos[1] as num).toDouble();

    generateKey<KeyFrameDouble>(
        vertex, animation, frame, PathVertexBase.xPropertyKey)
      .value = xValue;
    generateKey<KeyFrameDouble>(
        vertex, animation, frame, PathVertexBase.yPropertyKey)
      .value = yValue;
  }

  @protected
  Object getValueProperty(String propName) {
    final keyFrameData = value as Map<String, Object>;
    return keyFrameData[propName];
  }
}

class KeyFrameStraightVertexConverter extends KeyFrameVertexConverter {
  const KeyFrameStraightVertexConverter(
      Map value, int interpolatorType, List interpolatorCurve)
      : super(value, interpolatorType, interpolatorCurve);

  @override
  void convertKey(Component component, LinearAnimation animation, int frame) {
    if (component is! StraightVertexBase) {
      throw StateError(
          'Cannot add vertex keyframes to ${component.runtimeType}');
    }

    super.convertKey(component, animation, frame);

    final straightVertex = component as StraightVertexBase;
    final radiusValue = getValueProperty('radius') as num;

    generateKey<KeyFrameDouble>(
        straightVertex, animation, frame, StraightVertexBase.radiusPropertyKey)
      .value = radiusValue.toDouble();
  }
}

class KeyFrameMirroredVertexConverter extends KeyFrameVertexConverter {
  const KeyFrameMirroredVertexConverter(
      Map value, int interpolatorType, List interpolatorCurve)
      : super(value, interpolatorType, interpolatorCurve);

  @override
  void convertKey(Component cubicVertex, LinearAnimation animation, int frame) {
    if (cubicVertex is! CubicMirroredVertexBase) {
      throw StateError(
          'Cannot add vertex keyframes to ${cubicVertex.runtimeType}');
    }

    super.convertKey(cubicVertex, animation, frame);
    final mirroredVertex = cubicVertex as CubicMirroredVertexBase;
    final pos = getValueProperty('pos') as List;
    // final inValue = getValueProperty('in') as List;
    final outValue = getValueProperty('out') as List;

    final rotation = PathPointConverter.getRotation(pos, outValue);
    final distance = PathPointConverter.getDistance(pos, outValue);

    generateKey<KeyFrameDouble>(mirroredVertex, animation, frame,
        CubicMirroredVertexBase.rotationPropertyKey)
      .value = rotation;

    generateKey<KeyFrameDouble>(mirroredVertex, animation, frame,
        CubicMirroredVertexBase.distancePropertyKey)
      .value = distance;
  }
}

class KeyFrameDetachedVertexConverter extends KeyFrameVertexConverter {
  const KeyFrameDetachedVertexConverter(
      Map value, int interpolatorType, List interpolatorCurve)
      : super(value, interpolatorType, interpolatorCurve);

  @override
  void convertKey(Component component, LinearAnimation animation, int frame) {
    if (component is! CubicDetachedVertexBase) {
      throw StateError(
          'Cannot add vertex keyframes to ${component.runtimeType}');
    }

    super.convertKey(component, animation, frame);
    final detachedVertex = component as CubicDetachedVertexBase;
    final pos = getValueProperty('pos') as List;
    final inValue = getValueProperty('in') as List;
    final outValue = getValueProperty('out') as List;

    final inRotation = PathPointConverter.getRotation(pos, inValue);
    final outRotation = PathPointConverter.getRotation(pos, outValue);
    final inDistance = PathPointConverter.getDistance(pos, inValue);
    final outDistance = PathPointConverter.getDistance(pos, outValue);

    generateKey<KeyFrameDouble>(detachedVertex, animation, frame,
        CubicDetachedVertexBase.inRotationPropertyKey)
      .value = inRotation;

    generateKey<KeyFrameDouble>(detachedVertex, animation, frame,
        CubicDetachedVertexBase.outRotationPropertyKey)
      .value = outRotation;

    generateKey<KeyFrameDouble>(detachedVertex, animation, frame,
        CubicDetachedVertexBase.inDistancePropertyKey)
      .value = inDistance;

    generateKey<KeyFrameDouble>(detachedVertex, animation, frame,
        CubicDetachedVertexBase.outDistancePropertyKey)
      .value = outDistance;
  }
}

class KeyFrameAsymmetricVertexConverter extends KeyFrameVertexConverter {
  const KeyFrameAsymmetricVertexConverter(
      Map value, int interpolatorType, List interpolatorCurve)
      : super(value, interpolatorType, interpolatorCurve);

  @override
  void convertKey(Component component, LinearAnimation animation, int frame) {
    if (component is! CubicAsymmetricVertexBase) {
      throw StateError(
          'Cannot add vertex keyframes to ${component.runtimeType}');
    }

    super.convertKey(component, animation, frame);
    final detachedVertex = component as CubicAsymmetricVertex;
    final pos = getValueProperty('pos') as List;
    final inValue = getValueProperty('in') as List;
    final outValue = getValueProperty('out') as List;

    final rotation = PathPointConverter.getRotation(pos, outValue);
    final inDistance = PathPointConverter.getDistance(pos, inValue);
    final outDistance = PathPointConverter.getDistance(pos, outValue);

    generateKey<KeyFrameDouble>(detachedVertex, animation, frame,
        CubicAsymmetricVertexBase.rotationPropertyKey)
      .value = rotation;

    generateKey<KeyFrameDouble>(detachedVertex, animation, frame,
        CubicAsymmetricVertexBase.inDistancePropertyKey)
      .value = inDistance;

    generateKey<KeyFrameDouble>(detachedVertex, animation, frame,
        CubicAsymmetricVertexBase.outDistancePropertyKey)
      .value = outDistance;
  }
}
