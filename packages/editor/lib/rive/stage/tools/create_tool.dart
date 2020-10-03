import 'package:rive_core/artboard.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/rive/stage/stage_drawable.dart';
import 'package:rive_editor/rive/stage/tools/auto_tool.dart';
import 'package:rive_editor/rive/stage/tools/draggable_tool.dart';
import 'package:rive_editor/rive/stage/tools/stage_tool.dart';
import 'package:meta/meta.dart';
import 'package:utilities/restorer.dart';

/// Handles registering a default draw pass for tools that do simple drawing.
abstract class CreateTool extends StageTool with DraggableTool {
  @override
  Iterable<StageDrawPass> get drawPasses =>
      [StageDrawPass(draw, order: 1000, inWorldSpace: false)];

  Restorer _restoreSelection;
  Restorer _restoreAutoKey;

  @override
  @mustCallSuper
  bool activate(Stage stage) {
    if (!super.activate(stage)) {
      return false;
    }

    _restoreSelection?.restore();
    _restoreSelection = stage.suppressSelection();
    return true;
  }

  @override
  void deactivate() {
    _restoreSelection?.restore();
    super.deactivate();
  }

  @override
  void click(Artboard artboard, Vec2D worldMouse) {
    // This is null-conditionaled as some tools (like the arboard create tool)
    // may not have an active artboard yet.
    _restoreAutoKey = artboard?.context?.suppressAutoKey();
  }

  @override
  bool endClick() {
    _restoreAutoKey?.restore();
    stage.tool = AutoTool.instance;
    return true;
  }

  @override
  bool validateDrag() => validateClick();
}
