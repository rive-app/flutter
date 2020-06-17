import 'package:rive_editor/rive/stage/stage_drawable.dart';
import 'package:rive_editor/rive/stage/tools/draggable_tool.dart';
import 'package:rive_editor/rive/stage/tools/stage_tool.dart';

/// Handles registering a default draw pass for tools that do simple drawing.
abstract class DrawableTool extends StageTool with DraggableTool {
  @override
  Iterable<StageDrawPass> get drawPasses =>
      [StageDrawPass(this, order: 1000, inWorldSpace: false)];
}
