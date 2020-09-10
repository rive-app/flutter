import 'dart:typed_data';

import 'package:rive_core/bones/cubic_weight.dart';
import 'package:rive_core/bones/weight.dart';
import 'package:rive_core/bones/weighted_vertex.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/src/generated/shapes/cubic_vertex_base.dart';
export 'package:rive_core/src/generated/shapes/cubic_vertex_base.dart';

abstract class CubicVertex extends CubicVertexBase {
  Vec2D get outPoint;
  Vec2D get inPoint;

  set outPoint(Vec2D value);
  set inPoint(Vec2D value);

  @override
  Vec2D get renderTranslation => weight?.translation ?? super.renderTranslation;

  Vec2D get renderIn => weight?.inTranslation ?? inPoint;
  Vec2D get renderOut => weight?.outTranslation ?? outPoint;

  @override
  void deform(Mat2D world, Float32List boneTransforms) {
    super.deform(world, boneTransforms);

    Weight.deform(outPoint[0], outPoint[1], weight.outIndices, weight.outValues,
        world, boneTransforms, weight.outTranslation);
    Weight.deform(inPoint[0], inPoint[1], weight.inIndices, weight.inValues,
        world, boneTransforms, weight.inTranslation);
  }

  // -> editor-only
  bool accumulateAngle = false;

  // -> editor-only
  @override
  void cloneWeight(Weight from) {
    if (from.coreType == CubicWeightBase.typeKey) {
      appendChild(from);
    } else {
      initWeight();
      weight.inIndices = from.indices;
      weight.inValues = from.values;
      weight.indices = from.indices;
      weight.values = from.values;
      weight.outIndices = from.indices;
      weight.outValues = from.values;
      from.remove();
    }
  }

  @override
  List<WeightedVertex> get weightedVertices {
    var helpers = super.weightedVertices;
    helpers.add(InWeight(this));
    helpers.add(OutWeight(this));
    return helpers;
  }

  @override
  void initWeight() {
    assert(context != null && context.isBatchAdding);
    var weight = CubicWeight();
    context.addObject(weight);
    appendChild(weight);
  }
  // <- editor-only
}

// -> editor-only
class InWeight extends WeightedVertex {
  final CubicVertex vertex;

  InWeight(this.vertex);

  @override
  int get weightIndices => vertex.weight.inIndices;

  @override
  set weightIndices(int value) => vertex.weight.inIndices = value;

  @override
  int get weights => vertex.weight.inValues;

  @override
  set weights(int value) => vertex.weight.inValues = value;
}

class OutWeight extends WeightedVertex {
  final CubicVertex vertex;

  OutWeight(this.vertex);

  @override
  int get weightIndices => vertex.weight.outIndices;

  @override
  set weightIndices(int value) => vertex.weight.outIndices = value;

  @override
  int get weights => vertex.weight.outValues;

  @override
  set weights(int value) => vertex.weight.outValues = value;
}
// <- editor-only
