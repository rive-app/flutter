import 'package:rive_core/bones/cubic_weight.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/src/generated/shapes/cubic_vertex_base.dart';
export 'package:rive_core/src/generated/shapes/cubic_vertex_base.dart';

abstract class CubicVertex extends CubicVertexBase {
  CubicWeight _weight;

  Vec2D get outPoint;
  Vec2D get inPoint;

  set outPoint(Vec2D value);
  set inPoint(Vec2D value);

  @override
  Vec2D get renderTranslation =>
      _weight?.translation ?? super.renderTranslation;

  Vec2D get renderIn => _weight?.inTranslation ?? inPoint;
  Vec2D get renderOut => _weight?.outTranslation ?? outPoint;

  // @override
  // void deform(Mat2D world, Float32List boneTransforms) {
  //   super.deform(world, boneTransforms);

  //   PathVertex.deformWeighted(outPoint[0], outPoint[1], outWeightIndices,
  //       outWeights, world, boneTransforms, _renderOut ??= Vec2D());
  //   PathVertex.deformWeighted(inPoint[0], inPoint[1], inWeightIndices,
  //       inWeights, world, boneTransforms, _renderIn ??= Vec2D());
  // }

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

  @override
  void inWeightIndicesChanged(int from, int to) {}

  @override
  void inWeightsChanged(int from, int to) {}

  @override
  void outWeightIndicesChanged(int from, int to) {}

  @override
  void outWeightsChanged(int from, int to) {}

  @override
  void childAdded(Component component) {
    super.childAdded(component);
    if (component is CubicWeight) {
      _weight = component;
    }
  }

  @override
  void childRemoved(Component component) {
    super.childRemoved(component);
    if (_weight == component) {
      _weight = null;
    }
  }

  // -> editor-only
  @override
  void initWeight() {
    assert(context != null && context.isBatchAdding);
    var weight = CubicWeight();
    context.addObject(weight);
    appendChild(weight);
  }

  @override
  void clearWeight() {
    _weight?.remove();
  }
  // <- editor-only
}
