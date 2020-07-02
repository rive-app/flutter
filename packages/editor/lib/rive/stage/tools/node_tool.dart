import 'package:rive_editor/rive/stage/tools/create_tool.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/node.dart';
import 'package:rive_editor/packed_icon.dart';

class NodeTool extends CreateTool {
  @override
  Iterable<PackedIcon> get cursorName => PackedIcon.cursorAdd;

  static final NodeTool instance = NodeTool._();
  NodeTool._();

  /// Tracks the created node while a drag operation is in effect
  Node _node;

  @override
  void click(Artboard artboard, Vec2D worldMouse) {
    super.click(artboard, worldMouse);
    _node = _createNode(artboard, worldMouse);
  }

  @override
  Iterable<PackedIcon> get icon => PackedIcon.toolNode;

  @override
  bool endClick() {
    _node = null;
    return super.endClick();
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
  void endDrag() {}
}
