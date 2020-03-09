import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/src/generated/shapes/path_vertex_base.dart';
export 'package:rive_core/src/generated/shapes/path_vertex_base.dart';

abstract class PathVertex extends PathVertexBase {
  Vec2D get translation => Vec2D.fromValues(x, y);
  set translation(Vec2D value) {
    x = value[0];
    y = value[1];
  }

  @override
  String toString() {
    return translation.toString();
  }
}
