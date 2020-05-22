import 'package:rive_core/math/vec2d.dart';
import 'package:vector_math/vector_math.dart';

extension Vec2DVectorHelper on Vec2D {
  Vector2 toVector2() => Vector2.fromFloat32List(values);
}

extension Vector2DVec2Helper on Vector2 {
  Vec2D toVec2D() => Vec2D.fromValues(x, y);
}
