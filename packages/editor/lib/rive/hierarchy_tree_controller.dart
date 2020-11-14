import 'package:core/debounce.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/backboard.dart';
import 'package:rive_core/bones/root_bone.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/event.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/transform_component.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/popup/context_popup.dart';
import 'package:rive_editor/widgets/popup/list_popup.dart';
import 'package:tree_widget/flat_tree_item.dart';
import 'package:tree_widget/tree_controller.dart';
import 'package:rive_editor/rive/component_tree_controller.dart';
import 'package:utilities/utilities.dart';

import 'stage/stage_item.dart';

/// Tree Controller for the hierarchy, requires rive context in order to
/// propagate selections.
class HierarchyTreeController extends ComponentTreeController {
  @override
  final OpenFileContext file;
  final Backboard backboard;
  Artboard _showingArtboard;
  final DetailedEvent<Component> _requestVisibility =
      DetailedEvent<Component>();

  /// Called by the tree hierarchy controller when it wants to ensure the
  /// component is visible.
  DetailListenable<Component> get requestVisibility => _requestVisibility;

  HierarchyTreeController(this.file)
      : backboard = file.core.backboard,
        super() {
    // TODO: should this controller by a RiveFileDelegate so it can remove items
    // from the expanded set when they are removed for good from the file?
    // Probably a good idea or at least optimize it to track expansion via
    // custom hash (like the id of an object in this case so that it works when
    // objects are re-hydrated/instanced after an undo.
    backboard.activeArtboardChanged.addListener(_activeArtboardChanged);
    // Listen for selection events so tree can expand
    file.selection.addListener(_onItemSelected);
    _updateActiveArtboard();
  }

  @override
  Iterable<Component> get data => childrenOf(_showingArtboard) ?? [];

  @override
  // ignore: must_call_super
  void dispose() {
    cancelDebounce(_updateActiveArtboard);
    // N.B. assumes backboard doesn't change.
    backboard.activeArtboardChanged.removeListener(_activeArtboardChanged);
    // Remove the item selection listener
    file.selection.removeListener(_onItemSelected);

    // See issue #1015
    //
    // Do we really need to dispose the super class here? This happens to be a
    // ChangeNotifier which then leaves anything still trying to unsubscribe in
    // a bad state. ListenableBuilders could still be listening here...
    // super.dispose();
  }

  void _activeArtboardChanged() {
    debounce(_updateActiveArtboard);
  }

  void _updateActiveArtboard() {
    if (_showingArtboard != backboard.activeArtboard) {
      _showingArtboard = backboard.activeArtboard;
      flatten();
    }
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
    if (desiredParent == null) {
      // Null parent means it's the artboard...
      if (target.item.data.parent == _showingArtboard) {
        desiredParent = _showingArtboard;
      }
    }
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
    var restoreAutoKey = file.core.suppressAutoKey();
    switch (state) {
      case DropState.above:
      case DropState.below:

        // Set<TreeItemChildren> toSort = {};
        var parentComponent = target.parent?.data;
        if (parentComponent == null) {
          // Null parent means it's the artboard...
          if (target.item.data.parent == _showingArtboard) {
            parentComponent = _showingArtboard;
          }
        }
        if (parentComponent is! ContainerComponent) {
          return;
        }
        var parentContainer = parentComponent as ContainerComponent;
        var parentChildren = parentContainer.children;
        // First remove from existing so that proximity is preserved
        for (final item in items) {
          var treeItem = item.data;
          treeItem.parent = null;
          // treeItem.parent.children.remove(treeItem);
        }

        // If we're dropping items below the selection, add them in reverse
        // order so they maitain their relative order.
        var iterateItems = state == DropState.above ? items : items.reversed;
        var inc = state == DropState.above ? -1 : 1;
        for (final item in iterateItems) {
          var treeItem = item.data;
          parentChildren.moveRelative(treeItem, target.item.data, inc);

          // re-parent last after changing index
          treeItem.parent = parentContainer;

          // Immediately sort fractional as we iterate so the next item can find
          // appropriate siblings.
          parentChildren.sortFractional();

          // We're including only Nodes and RootBones in this drag set to start
          // with, so no non-translating bones should be in here.
          if (treeItem is TransformComponent) {
            /// Keep the node in the same position it last was at before getting
            /// parented.
            treeItem.compensate();
          }
        }

        break;
      case DropState.into:
        var targetComponent = target.item.data;
        if (targetComponent is! ContainerComponent) {
          return;
        }
        var targetContainer = targetComponent as ContainerComponent;
        for (final item in items) {
          var treeItem = item.data;
          targetContainer.children.moveToEnd(treeItem);
          treeItem.parent = targetContainer;
          targetContainer.children.sortFractional();
          if (treeItem is TransformComponent) {
            /// Keep the node in the same position it last was at before getting
            /// parented.
            treeItem.compensate();
          }
        }
        break;
      default:
        break;
    }
    restoreAutoKey.restore();
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

  bool _suppressExpandSelected = false;
  @override
  void onTap(FlatTreeItem<Component> item) {
    _suppressExpandSelected = true;
    super.onTap(item);
    _suppressExpandSelected = false;
  }

  /// Expand the tree to an item when selected
  void _onItemSelected() {
    /// Expand to the last selected item:
    if (file.selection.items.isEmpty || _suppressExpandSelected) {
      return;
    }

    var topComponents = tops(file.selection.items
        .where(
          (item) =>
              item is StageItem<Component> &&
              item.showInHierarchy &&
              item.component != null,
        )
        .map((item) => (item as StageItem<Component>).component));

    if (topComponents.isNotEmpty) {
      expandTo(topComponents.first);
      _requestVisibility.notify(topComponents.first);
    }
  }

  @override
  List<FlatTreeItem<Component>> onDragStart(
      DragStartDetails details, FlatTreeItem<Component> item) {
    // Get the list of selected items.
    var items = super
        .onDragStart(details, item)
        .where((element) => element.data is Node || element.data is RootBone)
        .toSet();

    return tops(items).toList(growable: false);
  }

  @override
  void onRightClick(BuildContext context, PointerDownEvent event,
      FlatTreeItem<Component> item) {
    // All items in draw order have a stage item.
    if (!item.data.stageItem.isSelected) {
      file.select(item.data.stageItem);
    }
    double width = RiveTheme.find(context).dimensions.contextMenuWidth;
    ListPopup<PopupContextItem>.show(
      context,
      showArrow: false,
      position: event.position + const Offset(0, -6),
      width: width,
      itemBuilder: (popupContext, item, isHovered) =>
          item.itemBuilder(popupContext, isHovered),
      items: [
        if (item != null)
          PopupContextItem(
            'Reverse',
            select: () {
              // Reverse siblings.
              var parent = item.data.parent;
              if (parent == null) {
                return;
              }
              parent.children.reverse();
              file.core.captureJournalEntry();
            },
          ),
        PopupContextItem(
          'Reverse All',
          select: () {
            if (_showingArtboard == null) {
              return;
            }
            _showingArtboard.forAll((component) {
              switch (component.coreType) {
                case NodeBase.typeKey:
                case ArtboardBase.typeKey:
                  (component as ContainerComponent).children.reverse();
              }
              return true;
            });
            file.core.captureJournalEntry();
          },
        ),
      ],
    );
  }
}
