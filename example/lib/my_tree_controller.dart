import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:tree_widget/flat_tree_item.dart';
import 'package:tree_widget/tree_controller.dart';

import 'tree_item.dart';

class MyTreeController extends TreeController<TreeItem> {
  MyTreeController(List<TreeItem> data)
      : super(data, showTopLevelSeparator: true);

  /// Our data set will store properties, so we opt-in to having them computed a
  /// flattening time.
  @override
  bool get hasProperties => true;

  /// Abstract way to get the children of an item, without making storage
  /// assumptions.
  @override
  List<TreeItem> childrenOf(TreeItem treeItem) {
    return treeItem.children;
  }

  /// Move an item from one part of the tree to another.
  @override
  void drop(FlatTreeItem<TreeItem> target, DropState state,
      List<FlatTreeItem<TreeItem>> items) {
    switch (state) {
      case DropState.above:
      case DropState.below:
        Set<TreeItemChildren> toSort = {};
        var newParent = target.data.parent;
        // First remove from existing.
        for (final item in items) {
          var treeItem = item.data;
          treeItem.parent.children.remove(treeItem);
        }
        for (final item in items) {
          var treeItem = item.data;

          treeItem.parent = newParent;

          newParent.children.add(treeItem);
          if (state == DropState.above) {
            newParent.children.move(treeItem,
                before: target.prev?.parent == target.parent
                    ? target.prev.data
                    : null,
                after: target.data);
          } else {
            newParent.children.move(treeItem,
                before: target.data,
                after: target.next?.parent == target.parent
                    ? target.next.data
                    : null);
          }
          toSort.add(newParent.children);
        }

        for (final children in toSort) {
          children.sortFractional();
        }
        break;
      case DropState.into:
        for (final item in items) {
          var treeItem = item.data;
          treeItem.parent.children.remove(treeItem);
          treeItem.parent = target.data;
          target.data.children.append(treeItem);
          target.data.children.sortFractional();
        }
        break;
      default:
        break;
    }

    // Force re-flatten the tree (N.B. you should do this when the children
    // change some other way too, like an undo operation).
    flatten();
  }

  /// We currently don't handle disabling items in this tree.
  @override
  bool isDisabled(TreeItem treeItem) {
    return false;
  }

  /// Group PropertyTreeItem types as a seperate child grouping in the tree.
  @override
  bool isProperty(TreeItem treeItem) {
    return treeItem is PropertyTreeItem;
  }

  /// Right now we just return just the dragged item, but this is where you'd
  /// probably want to return the set of selected items. Because the tree
  /// doesn't make assumptions about this, it's up to the implementor to return
  /// which other items are also selected.
  @override
  List<FlatTreeItem<TreeItem>> onDragStart(
      DragStartDetails details, FlatTreeItem<TreeItem> item) {
    return [item];
  }

  @override
  void onMouseEnter(PointerEnterEvent event, FlatTreeItem<TreeItem> item) {
    if (item.data.selectionState.value == SelectionState.selected) {
      return;
    }
    item.data.select(SelectionState.hovered);
  }

  @override
  void onMouseExit(PointerExitEvent event, FlatTreeItem<TreeItem> item) {
    if (item.data.selectionState.value == SelectionState.selected) {
      return;
    }
    item.data.select(SelectionState.none);
  }

  /// Again, we don't handle contextual selections in this example so we don't
  /// go deselect existing selections. In Rive this will be left up to the app
  /// context which owns the selections.
  @override
  void onTap(FlatTreeItem<TreeItem> item) {
    item.data.select(item.data.selectionState.value == SelectionState.selected
        ? SelectionState.hovered
        : SelectionState.selected);
  }

  @override
  int spacingOf(TreeItem treeItem) {
    // Just a hacky way to test item spacing.
    if (treeItem.name == 'leg_left') {
      return 3;
    }
    return treeItem.name != 'eye_happy' && treeItem.parent is SoloTreeItem
        ? 2
        : 1;
  }
}
