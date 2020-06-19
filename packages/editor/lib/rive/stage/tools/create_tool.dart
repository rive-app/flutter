import 'package:rive_editor/rive/stage/stage_drawable.dart';
import 'package:rive_editor/rive/stage/tools/auto_tool.dart';
import 'package:rive_editor/rive/stage/tools/draggable_tool.dart';
import 'package:rive_editor/rive/stage/tools/stage_tool.dart';
import 'package:meta/meta.dart';

/// Handles registering a default draw pass for tools that do simple drawing.
abstract class CreateTool extends StageTool with DraggableTool {
  @override
  Iterable<StageDrawPass> get drawPasses =>
      [StageDrawPass(draw, order: 1000, inWorldSpace: false)];

  @override
  @mustCallSuper
  void endDrag() {
    stage.tool = AutoTool.instance;
  }
}
