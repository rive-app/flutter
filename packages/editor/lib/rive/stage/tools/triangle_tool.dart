import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/shapes/parametric_path.dart';
import 'package:rive_core/shapes/triangle.dart';
import 'package:rive_core/shapes/shape.dart';

import 'package:rive_editor/rive/stage/tools/shape_tool.dart';

class TriangleTool extends ShapeTool {
  static final TriangleTool instance = TriangleTool._();

  TriangleTool._();

  @override
  Shape shape(Vec2D worldMouse) => Shape()
    ..name = 'Triangle'
    ..x = worldMouse[0]
    ..y = worldMouse[1];

  @override
  ParametricPath get path => Triangle()
    ..name = 'Triangle Path';

  @override
  String get icon => 'tool-triangle';
}
