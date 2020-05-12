import 'package:cursor/cursor_view.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/rive/stage/tools/draggable_tool.dart';
import 'package:rive_editor/rive/stage/tools/stage_tool.dart';

/// Handles custom cursors for any tools that implements some sort of drawing

abstract class DrawableTool extends StageTool with DraggableTool {
  /// Custom drawing cursor
  CursorInstance _customCursor;

  /// Custom cursor for drawing
  static const cursorName = 'cursor-add';

  @override
  bool activate(Stage stage) {
    if (!super.activate(stage)) {
      return false;
    }
    _customCursor = stage.showCustomCursor(cursorName);
    return true;
  }

  @override
  void deactivate() {
    _customCursor?.remove();
    _customCursor = null;
  }

  @override
  void endDrag() {
    // Stage captures journal entries for us when a drag operation ends.
    // Ask the stage to switch back to the translate tool
    stage.activateAction(ShortcutAction.translateTool);
  }
}
