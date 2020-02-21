import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/shapes/ellipse.dart';
import 'package:rive_core/shapes/parametric_path.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:rive_editor/rive/stage/tools/shape_tool.dart';

class EllipseTool extends ShapeTool {
  static final EllipseTool instance = EllipseTool._();

  EllipseTool._();

  @override
  Shape shape(Vec2D worldMouse) => Shape()
    ..name = 'Ellipse'
    ..x = worldMouse[0]
    ..y = worldMouse[1]
    ..rotation = 0
    ..scaleX = 1
    ..scaleY = 1
    ..opacity = 1;

  @override
  ParametricPath get path => Ellipse()
    ..name = 'Ellipse Path'
    ..x = 0
    ..y = 0
    ..rotation = 0
    ..scaleX = 1
    ..scaleY = 1
    ..opacity = 1
    ..width = 0
    ..height = 0;

  @override
  String get icon => 'tool-ellipse';
}
