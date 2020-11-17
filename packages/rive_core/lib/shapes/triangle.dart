import 'package:rive_core/shapes/path_vertex.dart';
import 'package:rive_core/shapes/straight_vertex.dart';
import 'package:rive_core/src/generated/shapes/triangle_base.dart';

/// Export the Base class for external use (e.g. rive.dart)
export 'package:rive_core/src/generated/shapes/triangle_base.dart';

class Triangle extends TriangleBase {
  @override
  List<PathVertex> get vertices {
    double ox = -originX * width;
    double oy = -originY * height;

    return [
      StraightVertex()
        ..x = ox + width / 2
        ..y = oy,
      StraightVertex()
        ..x = ox + width
        ..y = oy + height,
      StraightVertex()
        ..x = ox
        ..y = oy + height
    ];
  }
}
