import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:tree_widget/flat_tree_item.dart';
import 'package:tree_widget/tree_controller.dart';

import 'stage/stage_item.dart';

/// Tree Controller for the hierarchy, requires rive context in order to
/// propagate selections.
class HierarchyTreeController extends TreeController<Component> {
  final OpenFileContext file;
  HierarchyTreeController(List<Artboard> artboards, {this.file})
      : super(artboards);

  @override
  List<Component> childrenOf(Component treeItem) =>
      treeItem is ContainerComponent
          ? treeItem.children
              // We only want to show items in the tree which are selectable, in
              // order to be selectable they must have a stageItem.
              .where((item) => item.stageItem != null)
              .toList(growable: false)
          : null;

  @override
  bool allowDrop(FlatTreeItem<Component> target, DropState state,
      List<FlatTreeItem<Component>> items) {
    if (!super.allowDrop(target, state, items)) {
      return false;
    }

    var desiredParent =
        state == DropState.into ? target.data : target.data.parent;
    for (final item in items) {
      if (!item.data.isValidParent(desiredParent)) {
        return false;
      }
    }
    return true;
  }

  @override
  void drop(FlatTreeItem<Component> target, DropState state,
      List<FlatTreeItem<Component>> items) {
    switch (state) {
      case DropState.above:
      case DropState.below:
        // Set<TreeItemChildren> toSort = {};
        var newParent = target.data.parent;
        // First remove from existing so that proximity is preserved
        for (final item in items) {
          var treeItem = item.data;
          treeItem.parent = null;
          // treeItem.parent.children.remove(treeItem);
        }
        for (final item in items) {
          var treeItem = item.data;
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

          // re-parent last after changing index
          treeItem.parent = newParent;
          // toSort.add(newParent.children);
        }

        // for (final children in toSort) {
        //   children.sortFractional();
        // }
        break;
      case DropState.into:
        var targetComponent = target.data;
        if (targetComponent is! ContainerComponent) {
          return;
        }
        var targetContainer = targetComponent as ContainerComponent;
        for (final item in items) {
          var treeItem = item.data;
          // treeItem.parent.children.remove(treeItem);
          // treeItem.parent = target.data;
          targetContainer.children.moveToEnd(treeItem);
          treeItem.parent = targetContainer;
          // targetContainer.addChild(treeItem);
          // target.data.children.append(treeItem);
          // target.data.children.sortFractional();
        }
        break;
      default:
        break;
    }
    file.core.captureJournalEntry();
  }

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
      file.select(item.data.stageItem);
    }
  }

  @override
  int spacingOf(Component treeItem) {
    return 1;
  }
}
