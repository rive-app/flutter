import 'package:rive_core/shapes/cubic_vertex.dart';
import 'package:rive_core/shapes/path_vertex.dart';
import 'package:rive_core/src/generated/shapes/ellipse_base.dart';
export 'package:rive_core/src/generated/shapes/ellipse_base.dart';

const double circleConstant = 0.55;

class Ellipse extends EllipseBase {
  Ellipse() {
    print("GOT ELLIPSE!");
  }
  @override
  List<PathVertex> get vertices => [
        CubicVertex()
          ..x = 0
          ..y = -radiusY
          ..inX = -radiusX * circleConstant
          ..inY = -radiusY
          ..outX = radiusX * circleConstant
          ..outY = -radiusY,
        CubicVertex()
          ..x = radiusX
          ..y = 0
          ..inX = radiusX
          ..inY = circleConstant * -radiusY
          ..outX = radiusX
          ..outY = circleConstant * radiusY,
        CubicVertex()
          ..x = 0
          ..y = radiusY
          ..inX = radiusX * circleConstant
          ..inY = radiusY
          ..outX = -radiusX * circleConstant
          ..outY = radiusY,
        CubicVertex()
          ..x = -radiusX
          ..y = 0
          ..inX = -radiusX
          ..inY = radiusY * circleConstant
          ..outX = -radiusX
          ..outY = -radiusY * circleConstant
      ];

  double get radiusX => width / 2;
  double get radiusY => height / 2;
}
