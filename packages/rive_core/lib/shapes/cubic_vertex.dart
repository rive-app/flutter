import 'dart:typed_data';

import 'package:rive_core/bones/cubic_weight.dart';
import 'package:rive_core/bones/weight.dart';
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

  // @override
  // void clearWeight() {
  //   super.clearWeight();
  //   _renderOut = _renderIn = null;
  //   inWeightIndices = inWeights = outWeightIndices = outWeights = 0;
  // }

  // @override
  // void initWeight() {
  //   super.initWeight();
  //   inWeightIndices = 1;
  //   inWeights = 255;
  //   outWeightIndices = 1;
  //   outWeights = 255;
  // }
  // <- editor-only

  // -> editor-only
  @override
  void initWeight() {
    assert(context != null && context.isBatchAdding);
    var weight = CubicWeight();
    context.addObject(weight);
    appendChild(weight);
  }
  // <- editor-only
}
