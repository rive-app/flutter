import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/event.dart';
import 'package:rive_editor/rive/managers/animation/editing_animation_manager.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:tree_widget/flat_tree_item.dart';
import 'package:tree_widget/tree_controller.dart';

import 'package:core/debounce.dart';

class KeyedObjectTreeController extends TreeController<KeyHierarchyViewModel> {
  KeyedObjectTreeController(this.animationManager) : super() {
    _subscription = animationManager.hierarchy.listen(_hierarchyChanged);
    animationManager.activeFile.selection.addListener(_onItemSelected);
  }

  final EditingAnimationManager animationManager;
  StreamSubscription<Iterable<KeyHierarchyViewModel>> _subscription;
  Iterable<KeyHierarchyViewModel> _data = [];

  final DetailedEvent<KeyedComponentViewModel> _requestVisibility =
      DetailedEvent<KeyedComponentViewModel>();

  /// Called by the tree hierarchy controller when it wants to ensure the
  /// component is visible.
  DetailListenable<KeyedComponentViewModel> get requestVisibility =>
      _requestVisibility;

  @override
  Iterable<KeyHierarchyViewModel> get data => _data;

  void _hierarchyChanged(Iterable<KeyHierarchyViewModel> animations) {
    _data = animations.toList();
    flatten();
  }

  /// Scroll to a component in the key tree when selected on the stage, if that
  /// component exists in the tree
  void _onItemSelected() {
    final file = animationManager.activeFile;
    if (file.selection.items.isEmpty) {
      return;
    }
    // Fetch the selected items
    final selectedItems = file.selection.items;
    // Fetch the keyedItems in the tree
    final keyedItems = animationManager.hierarchy.value;

    // Determine if any of the selected items map to the keyed items, and if
    // they do, get the first one

    killDaLoop:
    for (final selectedItem in selectedItems) {
      if (selectedItem is StageItem<Component>) {
        final selectedComponent = selectedItem.component;
        for (final keyedItem in keyedItems) {
          if (keyedItem is KeyedComponentViewModel) {
            final keyedComponent = keyedItem.component;
            if (selectedComponent == keyedComponent) {
              _requestVisibility.notify(keyedItem);
              break killDaLoop;
            }
          }
        }
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    _subscription.cancel();
    animationManager.activeFile.selection.removeListener(_onItemSelected);
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
    if (treeItem is KeyedPropertyViewModel) {
      return treeItem.label.isNotEmpty;
    }
    return true;
  }
}
