import 'dart:ui';

import 'package:rive_core/artboard.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/node.dart';
import 'package:rive_editor/rive/stage/tools/clickable_tool.dart';
import 'package:rive_editor/rive/stage/tools/drawable_tool.dart';

// TODO: update node translation to be in parent space.
class NodeTool extends DrawableTool with ClickableTool {
  static final NodeTool instance = NodeTool._();

  NodeTool._();
  Node _node;

  @override
  void onClick(Artboard artboard, Vec2D worldMouse) {
    final file = stage.file;
    var core = file.core;

    // final selection = rive.selection.items;
    final ContainerComponent parent = artboard;

    _node = Node()
      ..name = "Node"
      ..x = worldMouse[0]
      ..y = worldMouse[1];

    core.batchAdd(() {
      core.add(_node);
      parent.appendChild(_node);
    });

    // TODO: capture only if the mouse up resulted in no drag (drag will auto
    // capture on end).
    core.captureJournalEntry();
  }

  @override
  String get icon => 'tool-node';

  @override
  void draw(Canvas canvas) {}

  @override
  void updateDrag(Vec2D worldMouse) {
    if (_node == null) {
      return;
    }
    _node.x = worldMouse[0];
    _node.y = worldMouse[1];
  }

  @override
  void endDrag() {    _node = null;
    super.endDrag();
  }
}
