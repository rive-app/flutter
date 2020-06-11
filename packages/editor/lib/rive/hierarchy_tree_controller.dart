import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:rive_core/backboard.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/node.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/rive/stage/items/stage_shape.dart';
import 'package:tree_widget/flat_tree_item.dart';
import 'package:tree_widget/tree_controller.dart';
import 'package:rive_editor/rive/component_tree_controller.dart';

import 'stage/stage_item.dart';

/// Tree Controller for the hierarchy, requires rive context in order to
/// propagate selections.
class HierarchyTreeController extends ComponentTreeController {
  @override
  final OpenFileContext file;
  List<Component> _data = [];
  final Backboard backboard;

  HierarchyTreeController(this.file)
      : backboard = file.core.backboard,
        super() {
    // TODO: should this controller by a RiveFileDelegate so it can remove items
    // from the expanded set when they are removed for good from the file?
    // Probably a good idea or at least optimize it to track expansion via
    // custom hash (like the id of an object in this case so that it works when
    // objects are re-hydrated/instanced after an undo.
    backboard.activeArtboardChanged.addListener(_updateArtboard);
    // Listen for selection events so tree can expand
    file.selection.addListener(_onItemSelected);
    _updateArtboard();
  }

  @override
  Iterable<Component> get data => _data;

  set data(Iterable<Component> value) {
    _data = value.toList();
    flatten();
  }

  @override
  void dispose() {
    // N.B. assumes backboard doesn't change.
    backboard.activeArtboardChanged.removeListener(_updateArtboard);
    // Remove the item selection listener
    file.selection.removeListener(_onItemSelected);
    super.dispose();
  }

  void _updateArtboard() {
    data = [if (backboard.activeArtboard != null) backboard.activeArtboard];
  }

  @override
  Iterable<Component> childrenOf(Component treeItem) =>
      treeItem is ContainerComponent
          ? treeItem.children
              // We only want to show items in the tree which are selectable, in
              // order to be selectable they must have a stageItem.
              .where((item) =>
                  item.stageItem != null && item.stageItem.showInHierarchy)
              .toList(growable: false)
          : null;

  @override
  bool allowDrop(TreeDragOperationTarget<Component> target,
      List<FlatTreeItem<Component>> items) {
    if (!super.allowDrop(target, items)) {
      return false;
    }

    var desiredParent = target.parent?.data;
    // state == DropState.into ? target.data : target.data.parent;
    for (final item in items) {
      if (!item.data.isValidParent(desiredParent)) {
        return false;
      }
    }
    return true;
  }

  @override
  void drop(TreeDragOperationTarget<Component> target,
      List<FlatTreeItem<Component>> items) {
    var state = target.state;
    switch (state) {
      case DropState.above:
      case DropState.below:
        // Set<TreeItemChildren> toSort = {};
        var parentComponent = target.parent.data;
        if (parentComponent is! ContainerComponent) {
          return;
        }
        var parentContainer = parentComponent as ContainerComponent;
        // First remove from existing so that proximity is preserved
        for (final item in items) {
          var treeItem = item.data;
          treeItem.parent = null;
          // treeItem.parent.children.remove(treeItem);
        }
        for (final item in items) {
          var treeItem = item.data;
          if (state == DropState.above) {
            parentContainer.children.move(treeItem,
                before: target.item.prev?.parent == target.parent
                    ? target.item.prev.data
                    : null,
                after: target.item.data);
          } else {
            parentContainer.children.move(treeItem,
                before: target.item.data,
                after: target.item.next?.parent == target.parent
                    ? target.item.next.data
                    : null);
          }

          // re-parent last after changing index
          treeItem.parent = parentContainer;
          if (treeItem is Node) {
            /// Keep the node in the same position it last was at before getting
            /// parented.
            treeItem.compensate();
          }
          // toSort.add(newParent.children);
        }

        // for (final children in toSort) {
        //   children.sortFractional();
        // }
        break;
      case DropState.into:
        var targetComponent = target.item.data;
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
          if (treeItem is Node) {
            /// Keep the node in the same position it last was at before getting
            /// parented.
            treeItem.compensate();
          }
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
  int spacingOf(Component treeItem) {
    return 1;
  }

  @override
  void onRightClick(BuildContext context, PointerDownEvent event,
      FlatTreeItem<Component> item) {}

  /// Expand the tree to an item when selected
  void _onItemSelected() {
    for (final item in file.selection.items) {
      if (item is StageShape) {
        expandTo(item.component);
      }
    }
  }
}
