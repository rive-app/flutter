import 'package:rive_core/bounds_delegate.dart';
import 'package:rive_core/src/generated/shapes/straight_vertex_base.dart';
export 'package:rive_core/src/generated/shapes/straight_vertex_base.dart';

class StraightVertex extends StraightVertexBase {
  @override
  String toString() => 'x[$x], y[$y], r[$radius]';

  @override
  void radiusChanged(double from, double to) {
    path?.markPathDirty();
  }
}
