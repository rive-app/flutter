import 'package:rive_core/shapes/parametric_path.dart';
import 'package:rive_core/shapes/rectangle.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/rive/stage/tools/shape_tool.dart';

class RectangleTool extends ShapeTool {
  static final RectangleTool instance = RectangleTool._();

  RectangleTool._();

  @override
  String get shapeName => 'Rectangle';

  @override
  ParametricPath makePath() => Rectangle()..name = 'Rectangle Path';

  @override
  Iterable<PackedIcon> get icon => PackedIcon.toolRectangle;
}
