import 'package:cursor/cursor_view.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/rive/stage/tools/auto_tool.dart';
import 'package:rive_editor/rive/stage/tools/draggable_tool.dart';
import 'package:rive_editor/rive/stage/tools/stage_tool.dart';
import 'package:rive_editor/rive/stage/tools/translate_tool.dart';

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
    _addCursor();
    return true;
  }

  @override
  void deactivate() {
    super.deactivate();
    _removeCursor();
  }

  @override
  void endDrag() {
    /// Need to check if we're still the active tool (something could've
    /// switched the active tool causing endDrag).
    if (stage.tool == this) {
      stage.tool = AutoTool.instance;
    }
    return;
    // Stage captures journal entries for us when a drag operation ends.
    // Ask the stage to switch back to the translate tool
    stage.activateAction(ShortcutAction.translateTool);
  }

  @override
  void mouseExit(Artboard activeArtboard, Vec2D worldMouse) => _removeCursor();

  @override
  void mouseEnter(Artboard activeArtboard, Vec2D worldMouse) => _addCursor();

  void _addCursor() =>
      // In weird cases, cursor can be added twice
      _customCursor ??= stage.showCustomCursor(cursorName);

  void _removeCursor() {
    _customCursor?.remove();
    _customCursor = null;
  }
}
