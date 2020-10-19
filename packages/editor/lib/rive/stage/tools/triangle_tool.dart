import 'package:rive_core/shapes/parametric_path.dart';
import 'package:rive_core/shapes/triangle.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/rive/stage/tools/shape_tool.dart';

class TriangleTool extends ShapeTool {
  static final TriangleTool instance = TriangleTool._();

  TriangleTool._();

  @override
  ParametricPath makePath() => Triangle();

  @override
  Iterable<PackedIcon> get icon => PackedIcon.toolTriangle;
}
