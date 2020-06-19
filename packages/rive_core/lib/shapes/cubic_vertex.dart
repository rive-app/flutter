import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/src/generated/shapes/cubic_vertex_base.dart';

abstract class CubicVertex extends CubicVertexBase {
  Vec2D get outPoint;
  Vec2D get inPoint;

  // -> editor-only
  set outPoint(Vec2D value);
  set inPoint(Vec2D value);
  bool accumulateAngle = false;
  // <- editor-only
}
