import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:rive_editor/rive/managers/animation/editing_animation_manager.dart';
import 'package:tree_widget/flat_tree_item.dart';
import 'package:tree_widget/tree_controller.dart';

import 'package:core/debounce.dart';

class KeyedObjectTreeController extends TreeController<KeyHierarchyViewModel> {
  final EditingAnimationManager animationManager;
  StreamSubscription<Iterable<KeyHierarchyViewModel>> _subscription;
  Iterable<KeyHierarchyViewModel> _data = [];

  KeyedObjectTreeController(this.animationManager) : super() {
    _subscription = animationManager.hierarchy.listen(_hierarchyChanged);
  }

  @override
  Iterable<KeyHierarchyViewModel> get data => _data;

  void _hierarchyChanged(Iterable<KeyHierarchyViewModel> animations) {
    _data = animations.toList();
    flatten();
  }

  @override
  void dispose() {
    super.dispose();
    _subscription.cancel();
    cancelDebounce(flatten);
  }

  @override
  Iterable<KeyHierarchyViewModel> childrenOf(KeyHierarchyViewModel treeItem) =>
      treeItem.children;

  @override
  void drop(TreeDragOperationTarget<KeyHierarchyViewModel> target,
      List<FlatTreeItem<KeyHierarchyViewModel>> items) {}

  @override
  bool allowDrop(TreeDragOperationTarget<KeyHierarchyViewModel> target,
      List<FlatTreeItem<KeyHierarchyViewModel>> items) {
    return false;
  }

  @override
  bool isDisabled(KeyHierarchyViewModel treeItem) {
    return false;
  }

  @override
  bool isProperty(KeyHierarchyViewModel treeItem) => false;

  @override
  List<FlatTreeItem<KeyHierarchyViewModel>> onDragStart(
          DragStartDetails details, FlatTreeItem<KeyHierarchyViewModel> item) =>
      [item];

  @override
  void onMouseEnter(
      PointerEnterEvent event, FlatTreeItem<KeyHierarchyViewModel> item) {
    // animationManager.mouseOver.add(item.data.value);
  }

  @override
  void onMouseExit(
      PointerExitEvent event, FlatTreeItem<KeyHierarchyViewModel> item) {
    // animationManager.mouseOut.add(item.data.value);
  }

  @override
  void onTap(FlatTreeItem<KeyHierarchyViewModel> item) {
    // animationManager.select.add(item.data.value);
  }

  @override
  int spacingOf(KeyHierarchyViewModel treeItem) => 1;

  @override
  void onRightClick(BuildContext context, PointerDownEvent event,
      FlatTreeItem<KeyHierarchyViewModel> item) {}
  
  @override
  bool hasHorizontalLine(KeyHierarchyViewModel treeItem) {
    if(treeItem is KeyedPropertyViewModel) {
      return treeItem.label.isNotEmpty;
    }
    return true;
  }
}
