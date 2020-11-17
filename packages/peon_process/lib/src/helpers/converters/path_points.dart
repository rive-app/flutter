import 'dart:math';

import 'package:peon_process/converters.dart';
import 'package:rive_core/bones/cubic_weight.dart';
import 'package:rive_core/bones/weight.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/shapes/cubic_asymmetric_vertex.dart';
import 'package:rive_core/shapes/cubic_detached_vertex.dart';
import 'package:rive_core/shapes/cubic_mirrored_vertex.dart';
import 'package:rive_core/shapes/cubic_vertex.dart';
import 'package:rive_core/shapes/path_vertex.dart';
import 'package:rive_core/shapes/straight_vertex.dart';

class PointWeightFinalizer extends ConversionFinalizer {
  final Weight weight;

  const PointWeightFinalizer(PathVertexBase vertex, this.weight)
      : super(vertex);

  @override
  void finalize(Map<String, Component> fileComponents) {
    final vertex = component as PathVertexBase;
    final currentWeight =
        vertex.children.firstWhere((element) => element is Weight);
    assert(currentWeight != null);
    assert(currentWeight.runtimeType == weight.runtimeType);
    if (currentWeight is CubicWeight) {
      final cubicWeight = weight as CubicWeight;
      currentWeight
        ..values = cubicWeight.values
        ..indices = cubicWeight.indices
        ..inValues = cubicWeight.inValues
        ..inIndices = cubicWeight.inIndices
        ..outValues = cubicWeight.outValues
        ..outIndices = cubicWeight.outIndices;
    } else if (currentWeight is Weight) {
      currentWeight
        ..values = weight.values
        ..indices = weight.indices;
    }
  }
}

class PathPointConverter extends ComponentConverter {
  PathPointConverter(
      String pointType, RiveFile context, ContainerComponent maybeParent)
      : super(_getVertexFrom(pointType), context, maybeParent);

  static PathVertex _getVertexFrom(String pointType) {
    switch (pointType) {
      case 'S':
        return StraightVertex();
      case 'M':
        return CubicMirroredVertex();
      case 'D':
        return CubicDetachedVertex();
      case 'A':
        return CubicAsymmetricVertex();
      default:
        throw UnsupportedError('===== UNKNOWN VERTEX TYPE $pointType');
    }
  }

  @override
  void deserialize(Map<String, Object> jsonData) {
    super.deserialize(jsonData);

    final translation = jsonData['translation'];
    final inVec = jsonData['in'];
    final outVec = jsonData['out'];
    final radius = jsonData['radius'];
    final weights = jsonData['weights'];

    final pathVertex = component as PathVertexBase;

    if (translation is List) {
      pathVertex
        ..x = (translation[0] as num).toDouble()
        ..y = (translation[1] as num).toDouble();
    }

    if (pathVertex is StraightVertex) {
      pathVertex.radius = (radius as num).toDouble();
    } else if (pathVertex is CubicMirroredVertex) {
      // Cubic Mirrored Vertex needs a rotation and a distance.
      // In Flare a Mirrored vertex had:
      //    a translation, an in-point and an out-point.
      // Rotation and distance can be calculated from these:
      // - distance is just the distance between translation and (in or out)
      // - rotation
      pathVertex
        ..rotation = getRotation(translation as List, outVec as List)
        ..distance = getDistance(translation as List, outVec as List);
    } else if (pathVertex is CubicDetachedVertex) {
      pathVertex
        ..inRotation = getRotation(translation as List, inVec as List)
        ..inDistance = getDistance(translation as List, inVec as List)
        ..outRotation = getRotation(translation as List, outVec as List)
        ..outDistance = getDistance(translation as List, outVec as List);
    } else if (pathVertex is CubicAsymmetricVertex) {
      pathVertex
        ..rotation = getRotation(translation as List, outVec as List)
        ..inDistance = getDistance(translation as List, inVec as List)
        ..outDistance = getDistance(translation as List, outVec as List);
    }

    /**
     * A single vertex (either a point or a bezier control point), can have
     *  at most 4 bone connections. 
     * That is why the weights array is made of either 8 or 24 elements:
     * - 8 in the case of a straight path point
     * - 24 in the case of a mirrored/detached/asymmetric path point
     *    as those types need to have weight also for their control points.
     * The array is structured this way:
     * - The first 4 values in the array represent the indices of the 
     *    connected bone to this path point
     * - The second 4 values are the corresponding weights for the bone 
     *    at that index
     */
    if (weights is List && weights.isNotEmpty) {
      assert(weights.length % 8 == 0);

      Weight riveWeight;
      /**
       * Straight & Cubic vertices both contain regular indices values,
       * so they're extracted for both code paths here.
       */
      final boneIndices = weights.sublist(0, 4);
      final weightValues = weights.sublist(4, 8);
      if (pathVertex is StraightVertex) {
        int weightValue = 0, boneIdx = 0;
        for (int i = 0; i < 4; i++) {
          int currentBoneIdx = (boneIndices[i] as num).toInt();
          int currentWeightValue = ((weightValues[i] as num) * 255).floor();
          boneIdx = _setValueAtIndex(boneIdx, i, currentBoneIdx);
          weightValue = _setValueAtIndex(weightValue, i, currentWeightValue);
        }
        riveWeight = Weight()
          ..indices = boneIdx
          ..values = weightValue;
      } else if (pathVertex is CubicVertex) {
        final inBoneIndices = weights.sublist(8, 12);
        final inBoneValues = weights.sublist(12, 16);
        final outBoneIndices = weights.sublist(16, 20);
        final outBoneValues = weights.sublist(20, 24);

        int weightValue = 0, boneIdx = 0;
        int inWeightValue = 0, inBoneIdx = 0;
        int outWeightValue = 0, outBoneIdx = 0;
        for (int i = 0; i < 4; i++) {
          int currentBoneIdx = (boneIndices[i] as num).toInt();
          int currentWeightValue = ((weightValues[i] as num) * 255).floor();
          boneIdx = _setValueAtIndex(boneIdx, i, currentBoneIdx);
          weightValue = _setValueAtIndex(weightValue, i, currentWeightValue);

          int currentInBoneIdx = (inBoneIndices[i] as num).toInt();
          int currentInWeightValue = ((inBoneValues[i] as num) * 255).floor();
          inBoneIdx = _setValueAtIndex(inBoneIdx, i, currentInBoneIdx);
          inWeightValue =
              _setValueAtIndex(inWeightValue, i, currentInWeightValue);

          int currentOutBoneIdx = (outBoneIndices[i] as num).toInt();
          int currentOutWeightValue = ((outBoneValues[i] as num) * 255).floor();
          outBoneIdx = _setValueAtIndex(outBoneIdx, i, currentOutBoneIdx);
          outWeightValue =
              _setValueAtIndex(outWeightValue, i, currentOutWeightValue);
        }
        riveWeight = CubicWeight()
          ..values = weightValue
          ..indices = boneIdx
          ..inValues = inWeightValue
          ..inIndices = inBoneIdx
          ..outValues = outWeightValue
          ..outIndices = outBoneIdx;
      }

      super.addFinalizer(PointWeightFinalizer(pathVertex, riveWeight));
    }
  }

  int _setValueAtIndex(int byteValues, int byteIndex, int valueAtByte) {
    int bv = byteValues;
    bv &= ~(0xFF << (byteIndex * 8));
    bv = bv | (valueAtByte << (byteIndex * 8));
    return bv;
  }

  static double getDistance(List start, List end) {
    final x1 = (start[0] as num).toDouble();
    final x2 = (end[0] as num).toDouble();
    final y1 = (start[1] as num).toDouble();
    final y2 = (end[1] as num).toDouble();

    var dx = x1 - x2;
    var dy = y1 - y2;
    return sqrt(dx * dx + dy * dy);
  }

  static double getRotation(List first, List second) {
    final x1 = (first[0] as num).toDouble();
    final x2 = (second[0] as num).toDouble();
    final y1 = (first[1] as num).toDouble();
    final y2 = (second[1] as num).toDouble();
    final angle = atan2(y2 - y1, x2 - x1);
    return angle;
  }
}
