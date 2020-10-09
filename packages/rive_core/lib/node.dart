import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/src/generated/node_base.dart';
export 'package:rive_core/src/generated/node_base.dart';

class Node extends NodeBase {
  /// Sets the position of the Node
  set translation(Vec2D pos) {
    x = pos[0];
    y = pos[1];
  }

  @override
  void xChanged(double from, double to) {
    markTransformDirty();
  }

  @override
  void yChanged(double from, double to) {
    markTransformDirty();
  }

  AABB get localBounds => AABB.fromValues(x, y, x, y);

  // -> editor-only
  @override
  bool validate() => super.validate() && artboard != null;

  @override
  String get defaultName => 'Group';
  // <- editor-only
}
