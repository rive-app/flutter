import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/shapes/parametric_path.dart';
import 'package:rive_core/shapes/rectangle.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:rive_editor/rive/stage/tools/shape_tool.dart';

class RectangleTool extends ShapeTool {
  static final RectangleTool instance = RectangleTool._();

  RectangleTool._();

  @override
  Shape shape(Vec2D worldMouse) => Shape()
    ..name = 'Rectangle'
    ..x = worldMouse[0]
    ..y = worldMouse[1]
    ..rotation = 0
    ..scaleX = 1
    ..scaleY = 1
    ..opacity = 1;

  @override
  ParametricPath get path => Rectangle()
    ..name = 'Rectangle Path'
    ..x = 0
    ..y = 0
    ..rotation = 0
    ..scaleX = 1
    ..scaleY = 1
    ..opacity = 1
    ..width = 0
    ..height = 0
    ..cornerRadius = 0;

  @override
  String get icon => 'tool-rectangle';
}
