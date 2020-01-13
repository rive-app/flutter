import 'package:flutter/src/gestures/drag_details.dart';
import 'package:flutter/src/gestures/events.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/container_component.dart';
import 'package:tree_widget/flat_tree_item.dart';
import 'package:tree_widget/tree_controller.dart';
import 'package:rive_core/artboard.dart';

class HierarchyTreeController extends TreeController<Component> {
  HierarchyTreeController(List<Artboard> artboards) : super(artboards);

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
  void onMouseEnter(PointerEnterEvent event, FlatTreeItem<Component> item) {}

  @override
  void onMouseExit(PointerExitEvent event, FlatTreeItem<Component> item) {}

  @override
  void onTap(FlatTreeItem<Component> item) {}

  @override
  int spacingOf(Component treeItem) {
    return 1;
  }
}
