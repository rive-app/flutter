import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/shapes/path_vertex.dart';
import 'package:rive_core/src/generated/shapes/cubic_vertex_base.dart';
export 'package:rive_core/src/generated/shapes/cubic_vertex_base.dart';

class CubicVertex extends CubicVertexBase {

  Vec2D get outPoint => Vec2D.fromValues(outX, outY);
  Vec2D get inPoint => Vec2D.fromValues(inX, inY);

  @override
  VertexControlType get controlType =>
      VertexControlType.values[controlTypeValue];
  set controlType(VertexControlType value) {
    assert(value != VertexControlType.straight);
    controlTypeValue = value.index;
  }

  set outPoint(Vec2D value) {
    outX = value[0];
    outY = value[1];
  }

  set inPoint(Vec2D value) {
    inX = value[0];
    inY = value[1];
  }

  @override
  void inXChanged(double from, double to) {}

  @override
  void inYChanged(double from, double to) {}

  @override
  void outXChanged(double from, double to) {}

  @override
  void outYChanged(double from, double to) {}

  @override
  void controlTypeValueChanged(int from, int to) {}

  @override
  String toString() {
    return 'in $inX, $inY | ${translation.toString()} | out $outX, $outY';
  }
}
