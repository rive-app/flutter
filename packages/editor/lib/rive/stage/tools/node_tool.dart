import 'package:rive_editor/rive/stage/tools/auto_tool.dart';
import 'package:rive_editor/rive/stage/tools/draggable_tool.dart';
import 'package:rive_editor/rive/stage/tools/stage_tool.dart';
import 'package:utilities/restorer.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/node.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';

// TODO: update node translation to be in parent space.
class NodeTool extends StageTool with DraggableTool {
  @override
  Iterable<PackedIcon> get cursorName => PackedIcon.cursorAdd;

  static final NodeTool instance = NodeTool._();
  NodeTool._();

  /// Tracks the created node while a drag operation is in effect
  Node _node;
  Restorer _restoreAutoKey;

  @override
  void click(Artboard artboard, Vec2D worldMouse) {
    _restoreAutoKey = artboard.context.suppressAutoKey();
    _node = _createNode(artboard, worldMouse);
  }

  @override
  Iterable<PackedIcon> get icon => PackedIcon.toolNode;

  /// We handle completing the node placement operation here
  /// as it might have been dragged around a bit before being
  /// placed, so we can't do this in onClick
  @override
  bool endClick() {
    _restoreAutoKey?.restore();
    _node = null;
    stage.activateAction(ShortcutAction.translateTool);
    return true;
  }

  @override
  void updateDrag(Vec2D worldMouse) => _node?.translation = worldMouse;

  /// Create a new node and place it in space
  Node _createNode(ContainerComponent parent, Vec2D position) {
    final core = stage.file.core;

    final node = Node()
      ..name = 'Node'
      ..x = position[0]
      ..y = position[1];

    core.batchAdd(() {
      core.addObject(node);
      parent.appendChild(node);
    });

    return node;
  }

  @override
  void endDrag() {
    /// Need to check if we're still the active tool (something could've
    /// switched the active tool causing endDrag).
    if (stage.tool == this) {
      stage.tool = AutoTool.instance;
    }
  }
}
