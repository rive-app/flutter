import 'package:rive_core/src/generated/shapes/straight_vertex_base.dart';
export 'package:rive_core/src/generated/shapes/straight_vertex_base.dart';

class StraightVertex extends StraightVertexBase {
  @override
  void update(int dirt) {}

  @override
  String toString() => 'x[$x], y[$y], r[$radius]';

  @override
  void radiusChanged(double from, double to) {
    // TODO: implement radiusChanged
  }

  @override
  void xChanged(double from, double to) {
    // TODO: implement xChanged
  }

  @override
  void yChanged(double from, double to) {
    // TODO: implement yChanged
  }
}
