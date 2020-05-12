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
    onScreen();
    return true;
  }

  @override
  void deactivate() {
    super.deactivate();
    _removeCursor();
  }

  @override
  void endDrag() =>
      // Stage captures journal entries for us when a drag operation ends.
      // Ask the stage to switch back to the translate tool
      stage.activateAction(ShortcutAction.translateTool);

  @override
  void offScreen() => _removeCursor();

  @override
  void onScreen() => _customCursor = stage.showCustomCursor(cursorName);

  void _removeCursor() {
    _customCursor?.remove();
    _customCursor = null;
  }
}
