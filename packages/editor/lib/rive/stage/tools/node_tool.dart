import 'dart:ui';

import 'package:rive_core/artboard.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/node.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/rive/stage/tools/drawable_tool.dart';

// TODO: update node translation to be in parent space.
class NodeTool extends DrawableTool {
  static final NodeTool instance = NodeTool._();
  NodeTool._();

  /// Tracks the created node while a drag operation is in effect
  Node _node;

  @override
  void click(Artboard artboard, Vec2D worldMouse) {
    artboard.context.suppressAutoKey = true;
    _node = _createNode(artboard, worldMouse);
  }

  @override
  String get icon => 'tool-node';

  @override
  void draw(Canvas canvas) {}

  /// We handle completing the node placement operation here
  /// as it might have been dragged around a bit before being
  /// placed, so we can't do this in onClick
  @override
  bool endClick() {
    _node?.context?.suppressAutoKey = false;
    _node = null;
    stage.activateAction(ShortcutAction.translateTool);
    return true;
  }

  @override
  void updateDrag(Vec2D worldMouse) => _node?.pos = worldMouse;

  /// Create a new node and place it in space
  Node _createNode(ContainerComponent parent, Vec2D position) {
    final core = stage.file.core;

    final node = Node()
      ..name = 'Node'
      ..x = position[0]
      ..y = position[1];

    core.batchAdd(() {
      core.add(node);
      parent.appendChild(node);
    });

    return node;
  }
}
