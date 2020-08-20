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
