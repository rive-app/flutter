import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/src/generated/shapes/cubic_vertex_base.dart';

abstract class CubicVertex extends CubicVertexBase {
  Vec2D outPoint;
  Vec2D inPoint;

  // -> editor-only
  bool accumulateAngle = false;
  // <- editor-only
}
