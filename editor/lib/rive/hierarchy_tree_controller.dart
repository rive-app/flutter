import 'package:flutter/src/gestures/drag_details.dart';
import 'package:flutter/src/gestures/events.dart';
import 'package:tree_widget/flat_tree_item.dart';
import 'package:tree_widget/tree_controller.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/hierarchy_item.dart';

class HierarchyTreeController extends TreeController<HierarchyItem> {
  HierarchyTreeController(List<Artboard> artboards) : super(artboards);

  @override
  List<HierarchyItem> childrenOf(HierarchyItem treeItem) =>
      treeItem.hierarchyChildren;

  @override
  void drop(FlatTreeItem<HierarchyItem> target, DropState state,
      List<FlatTreeItem<HierarchyItem>> items) {}

  @override
  bool isDisabled(HierarchyItem treeItem) {
    return false;
  }

  @override
  bool isProperty(HierarchyItem treeItem) {
    return false;
  }

  @override
  List<FlatTreeItem<HierarchyItem>> onDragStart(
      DragStartDetails details, FlatTreeItem<HierarchyItem> item) {
    return [item];
  }

  @override
  void onMouseEnter(
      PointerEnterEvent event, FlatTreeItem<HierarchyItem> item) {}

  @override
  void onMouseExit(PointerExitEvent event, FlatTreeItem<HierarchyItem> item) {}

  @override
  void onTap(FlatTreeItem<HierarchyItem> item) {}

  @override
  int spacingOf(HierarchyItem treeItem) {
    return 1;
  }
}
