import 'package:rive_core/shapes/ellipse.dart';
import 'package:rive_core/shapes/parametric_path.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/rive/stage/tools/shape_tool.dart';

class EllipseTool extends ShapeTool {
  static final EllipseTool instance = EllipseTool._();

  EllipseTool._();

  @override
  ParametricPath makePath() => Ellipse();

  @override
  Iterable<PackedIcon> get icon => PackedIcon.toolEllipse;
}
