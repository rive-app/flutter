import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/container_component.dart';
import 'package:tree_widget/flat_tree_item.dart';
import 'package:tree_widget/tree_controller.dart';

import 'rive.dart';
import 'stage/stage_item.dart';

/// Tree Controller for the hierarchy, requires rive context in order to
/// propagate selections.
class HierarchyTreeController extends TreeController<Component> {
  final Rive rive;
  HierarchyTreeController(List<Artboard> artboards, {this.rive})
      : super(artboards);

  @override
  List<Component> childrenOf(Component treeItem) =>
      treeItem is ContainerComponent ? treeItem.children : null;

  @override
  void drop(FlatTreeItem<Component> target, DropState state,
      List<FlatTreeItem<Component>> items) {}

  @override
  bool isDisabled(Component treeItem) {
    return false;
  }

  @override
  bool isProperty(Component treeItem) {
    return false;
  }

  @override
  List<FlatTreeItem<Component>> onDragStart(
      DragStartDetails details, FlatTreeItem<Component> item) {
    return [item];
  }

  @override
  void onMouseEnter(PointerEnterEvent event, FlatTreeItem<Component> item) {
    item.data.stageItem.isHovered = true;
  }

  @override
  void onMouseExit(PointerExitEvent event, FlatTreeItem<Component> item) {
    item.data.stageItem.isHovered = false;
  }

  @override
  void onTap(FlatTreeItem<Component> item) {
    if (item.data.stageItem != null) {
      rive.select(item.data.stageItem);
    }
  }

  @override
  int spacingOf(Component treeItem) {
    return 1;
  }
}
