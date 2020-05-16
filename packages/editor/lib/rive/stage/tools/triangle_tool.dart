import 'package:rive_core/shapes/parametric_path.dart';
import 'package:rive_core/shapes/triangle.dart';
import 'package:rive_editor/rive/stage/tools/shape_tool.dart';

class TriangleTool extends ShapeTool {
  static final TriangleTool instance = TriangleTool._();

  TriangleTool._();

  @override
  String get shapeName => 'Triangle';

  @override
  ParametricPath makePath() => Triangle()..name = 'Triangle Path';

  @override
  String get icon => 'tool-triangle';
}
