import 'dart:ui';

import 'package:rive_core/artboard.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/node.dart';
import 'package:rive_editor/rive/stage/tools/clickable_tool.dart';
import 'package:rive_editor/rive/stage/tools/stage_tool.dart';

class NodeTool extends StageTool with ClickableTool {
  static final NodeTool instance = NodeTool._();

  NodeTool._();

  @override
  void onClick(Vec2D worldMouse) {
    final rive = stage.rive;
    final file = rive.file.value;

    // TODO: use Active artboard instead.
    final artboard = file.artboards.first;
    // TODO: compute actual parent from selection.
    // final selectedItems = rive.selection.items;

    final ContainerComponent parent = artboard;
    Mat2D parentWorld;
    if (parent is Artboard) {
      parentWorld = Mat2D.fromTranslation(parent.originWorld);
    } else if (parent is Node) {
      parentWorld = parent.renderTransform;
    }

    final parentWorldInverse = Mat2D();
    Mat2D.invert(parentWorldInverse, parentWorld);
    final itemTranslation =
        Vec2D.transformMat2D(Vec2D(), worldMouse, parentWorldInverse);

    final node = Node()
      ..name = "Node"
      ..x = itemTranslation[0]
      ..y = itemTranslation[1];

    file.batchAdd(() {
      file.add(node);
      parent.appendChild(node);
    });
  }

  @override
  String get icon => 'tool-node';

  @override
  void paint(Canvas canvas) {}
}
