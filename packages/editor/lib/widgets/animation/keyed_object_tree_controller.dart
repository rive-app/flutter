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

  /// Event to request that a model be visible in the hierarchy
  final DetailedEvent<KeyHierarchyViewModel> _requestVisibility =
      DetailedEvent<KeyHierarchyViewModel>();

  /// Event that requests a set of models to be highlighted
  final DetailedEvent<Set<KeyHierarchyViewModel>> _highlight =
      DetailedEvent<Set<KeyHierarchyViewModel>>();

  /// Called by the  hierarchy when it wants to ensure a model is visible
  DetailListenable<KeyHierarchyViewModel> get requestVisibility =>
      _requestVisibility;

  /// Called by the  hierarchy when it wants to ensure a set of models are
  /// highlighted
  DetailListenable<Set<KeyHierarchyViewModel>> get highlight => _highlight;

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
      // Wipe out any highlighted items
      _highlight.notify({});
      return;
    }
    // selected items
    final selectedItems = file.selection.items;
    final selectedComponents =
        selectedItems.whereType<StageItem<Component>>().map((i) => i.component);
    // Fetch the keyed components, mapped to their respective models
    final keyedComponentsMap = animationManager.componentViewModels;
    final keyedComponents = keyedComponentsMap.keys;

    // Determine if any of the selected components is keyed , and if so, scroll
    // to and select the first one
    for (final selectedComponent in selectedComponents) {
      if (keyedComponents.contains(selectedComponent)) {
        final model = keyedComponentsMap[selectedComponent];
        // expand the tree if necessary
        expandTo(model);
        // scroll to make the item visible if necessary
        _requestVisibility.notify(model);
        // highlight the item
        _highlight.notify({model});
        // break out of the function, as job's done
        return;
      }
    }
    // If we've not broken out, then we've found nothing, so ensure any
    // highlighted items are cleared
    _highlight.notify({});
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
    animationManager.mouseOver.add(item.data);
  }

  @override
  void onMouseExit(
      PointerExitEvent event, FlatTreeItem<KeyHierarchyViewModel> item) {
    animationManager.mouseExit.add(item.data);
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

  @override
  void selectTreeItem(KeyHierarchyViewModel item) {
    animationManager.select.add(item);
  }

  @override
  void selectMultipleTreeItems(Iterable<KeyHierarchyViewModel> items) {
    animationManager.selectMultiple.add(items);
  }
}
