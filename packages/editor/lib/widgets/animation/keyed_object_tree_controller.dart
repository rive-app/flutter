import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:rive_editor/rive/managers/animation/editing_animation_manager.dart';
import 'package:tree_widget/flat_tree_item.dart';
import 'package:tree_widget/tree_controller.dart';

import 'package:core/debounce.dart';

class KeyedObjectTreeController extends TreeController<KeyedViewModel> {
  final EditingAnimationManager animationManager;
  StreamSubscription<Iterable<KeyedViewModel>> _subscription;
  Iterable<KeyedViewModel> _data = [];

  KeyedObjectTreeController(this.animationManager) : super() {
    _subscription = animationManager.hierarchy.listen(_hierarchyChanged);
  }

  @override
  Iterable<KeyedViewModel> get data => _data;

  void _hierarchyChanged(Iterable<KeyedViewModel> animations) {
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
  List<KeyedViewModel> childrenOf(KeyedViewModel treeItem) => treeItem.children;

  @override
  void drop(FlatTreeItem<KeyedViewModel> target, DropState state,
      List<FlatTreeItem<KeyedViewModel>> items) {}

  @override
  bool allowDrop(FlatTreeItem<KeyedViewModel> item, DropState state,
      List<FlatTreeItem<KeyedViewModel>> items) {
    return false;
  }

  @override
  bool isDisabled(KeyedViewModel treeItem) {
    return false;
  }

  @override
  bool isProperty(KeyedViewModel treeItem) => false;

  @override
  List<FlatTreeItem<KeyedViewModel>> onDragStart(
          DragStartDetails details, FlatTreeItem<KeyedViewModel> item) =>
      [item];

  @override
  void onMouseEnter(
      PointerEnterEvent event, FlatTreeItem<KeyedViewModel> item) {
    // animationManager.mouseOver.add(item.data.value);
  }

  @override
  void onMouseExit(PointerExitEvent event, FlatTreeItem<KeyedViewModel> item) {
    // animationManager.mouseOut.add(item.data.value);
  }

  @override
  void onTap(FlatTreeItem<KeyedViewModel> item) {
    // animationManager.select.add(item.data.value);
  }

  @override
  int spacingOf(KeyedViewModel treeItem) => 1;

  @override
  void onRightClick(BuildContext context, PointerDownEvent event,
      FlatTreeItem<KeyedViewModel> item) {}
}
