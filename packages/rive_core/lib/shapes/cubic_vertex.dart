import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/src/generated/shapes/cubic_vertex_base.dart';
export 'package:rive_core/src/generated/shapes/cubic_vertex_base.dart';

abstract class CubicVertex extends CubicVertexBase {
  Vec2D get outPoint;
  Vec2D get inPoint;

  set outPoint(Vec2D value);
  set inPoint(Vec2D value);

  // -> editor-only
  bool accumulateAngle = false;

  @override
  void clearWeight() {
    super.clearWeight();
    inWeightIndices = inWeights = outWeightIndices = outWeights = 0;
  }

  @override
  void initWeight() {
    super.initWeight();
    inWeightIndices = 1;
    inWeights = 255;
    outWeightIndices = 1;
    outWeights = 255;
  }
  // <- editor-only

  @override
  void inWeightIndicesChanged(int from, int to) {}

  @override
  void inWeightsChanged(int from, int to) {}

  @override
  void outWeightIndicesChanged(int from, int to) {}

  @override
  void outWeightsChanged(int from, int to) {}
}
