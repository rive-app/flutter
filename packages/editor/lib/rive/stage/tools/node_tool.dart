import 'dart:ui';

import 'package:rive_core/artboard.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
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
    final selection = rive.selection.items;
    final ContainerComponent parent = _getParentFrom(selection) ?? artboard;

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

  // If StageItems are selected, validate if the first of them can be used
  // as a valid parent for newly created node.
  //
  // Returns a valid parent, or null.
  ContainerComponent _getParentFrom(Set<SelectableItem> selection) {
    ContainerComponent parent;

    // This sucks.
    if (selection.isNotEmpty) {
      final first = selection.first;
      if (first is StageItem) {
        final dynamic maybeParent = first.component;
        if (maybeParent is ContainerComponent) {
          // I want to know if the current selection is a valid parent
          // for my newly created Node.
          final nodeValidParents = Component.validParents[Node];
          final isValid = nodeValidParents.contains(maybeParent.runtimeType);
          if (isValid) {
            parent = maybeParent;
          }
        }
      }
    }

    return parent;
  }

  @override
  String get icon => 'tool-node';

  @override
  void paint(Canvas canvas) {}
}
