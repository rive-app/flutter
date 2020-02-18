import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/src/generated/shapes/cubic_vertex_base.dart';
export 'package:rive_core/src/generated/shapes/cubic_vertex_base.dart';

class CubicVertex extends CubicVertexBase {
  @override
  void update(int dirt) {}

  Vec2D get outPoint => Vec2D.fromValues(outX, outY);
  Vec2D get inPoint => Vec2D.fromValues(inX, inY);

  set outPoint(Vec2D value) {
    outX = value[0];
    outY = value[1];
  }

  set inPoint(Vec2D value) {
    inX = value[0];
    inY = value[1];
  }
}
