import 'package:rive_core/shapes/parametric_path.dart';
import 'package:rive_core/shapes/rectangle.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/rive/stage/tools/shape_tool.dart';

class RectangleTool extends ShapeTool {
  static final RectangleTool instance = RectangleTool._();

  RectangleTool._();

  @override
  ParametricPath makePath() => Rectangle();

  @override
  Iterable<PackedIcon> get icon => PackedIcon.toolRectangle;
}
