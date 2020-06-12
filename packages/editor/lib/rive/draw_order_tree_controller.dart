import 'package:core/core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:rive_core/artboard.dart';
import 'package:rive_core/backboard.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/drawable.dart';
import 'package:rive_editor/rive/managers/animation/editing_animation_manager.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/component_tree_controller.dart';

import 'package:tree_widget/flat_tree_item.dart';
import 'package:tree_widget/tree_controller.dart';

import 'stage/stage_item.dart';

/// Tree Controller for the draw order, requires rive context in order to
/// propagate selections.
class DrawOrderTreeController extends ComponentTreeController {
  @override
  final OpenFileContext file;
  final Backboard backboard;
  Artboard activeArtboard;
  DrawableList _drawables = DrawableList();
  DrawOrderTreeController({this.file})
      : backboard = file.core.backboard,
        super() {
    backboard.activeArtboardChanged.addListener(_activeArtboardChanged);
    _activeArtboardChanged();
  }

  void _activeArtboardChanged() {
    activeArtboard?.drawOrderChanged?.removeListener(flatten);
    activeArtboard = backboard.activeArtboard;
    activeArtboard?.drawOrderChanged?.addListener(flatten);
    _drawables = activeArtboard?.drawables ?? DrawableList();
    flatten();
  }

  @override
  void dispose() {
    activeArtboard?.drawOrderChanged?.removeListener(flatten);
    backboard.activeArtboardChanged.removeListener(_activeArtboardChanged);
    super.dispose();
  }

  @override
  Iterable<Component> get data => _drawables.reversed;

  set data(Iterable<Component> value) {
    assert(false, "not supported");
  }

  @override
  Iterable<Component> childrenOf(Component treeItem) => treeItem is Artboard
      ? treeItem.children
          // We only want to show items in the tree which are selectable, in
          // order to be selectable they must have a stageItem.
          .where((item) => item.stageItem != null)
          .toList(growable: false)
      : null;

  @override
  bool isDisabled(Component treeItem) => false;

  @override
  bool isProperty(Component treeItem) => false;

  @override
  void onMouseEnter(PointerEnterEvent event, FlatTreeItem<Component> item) =>
      item.data.stageItem.isHovered = true;

  @override
  void onMouseExit(PointerExitEvent event, FlatTreeItem<Component> item) =>
      item.data.stageItem.isHovered = false;

  @override
  int spacingOf(Component treeItem) => 1;

  FlatTreeItem<Component> _previousExcluding(
      FlatTreeItem<Component> target, List<FlatTreeItem<Component>> items) {
    for (var item = target.prev; item != null; item = item.prev) {
      if (!items.contains(item)) {
        return item;
      }
    }
    return null;
  }

  FlatTreeItem<Component> _nextExcluding(
      FlatTreeItem<Component> target, List<FlatTreeItem<Component>> items) {
    for (var item = target.next; item != null; item = item.next) {
      if (!items.contains(item)) {
        return item;
      }
    }
    return null;
  }

  @override
  void drop(TreeDragOperationTarget<Component> target,
      List<FlatTreeItem<Component>> items) {
    FractionalIndex before, after;

    // Keep this here to patch things up if they go wrong, until there are more
    // tests for drag/drop draw order in odd sequences.

    // Fix it: reverse order.
    // before = const FractionalIndex.max(); after = const
    // FractionalIndex.min(); for (final f in flat) {before =
    // FractionalIndex.between(before, after); (f.data as Drawable).drawOrder =
    // before; print("ITEM ${f.data.name} ${(f.data as Drawable).drawOrder}");
    // }

    // return;
    var state = target.state;
    var item = target.item;
    switch (state) {
      case DropState.above:
        before =
            (_previousExcluding(item, items)?.data as Drawable)?.drawOrder ??
                const FractionalIndex.max();
        after = (item.data as Drawable).drawOrder;
        break;
      case DropState.below:
        before = (item.data as Drawable).drawOrder;
        after = (_nextExcluding(item, items)?.data as Drawable)?.drawOrder ??
            const FractionalIndex.min();
        break;
      default:
        break;
    }

    for (final item in items) {
      before = FractionalIndex.between(before, after);
      (item.data as Drawable).drawOrder = before;
    }
    var manager = file.editingAnimationManager.value;
    if (manager != null) {
      // If we're animating we should autokey the draw order as we just changed
      // it.
      manager.keyComponents.add(KeyComponentsEvent(
          components: [manager.animation.artboard],
          propertyKey: DrawableBase.drawOrderPropertyKey));
    }
    file.core.captureJournalEntry();
  }

  @override
  void onRightClick(BuildContext context, PointerDownEvent event,
      FlatTreeItem<Component> item) {
    // TODO: implement onRightClick
  }

  @override
  bool allowDrop(TreeDragOperationTarget<Component> target,
      List<FlatTreeItem<Component>> items) {
    if (!super.allowDrop(target, items)) {
      return false;
    }

    switch (target.state) {
      case DropState.above:
      case DropState.below:
        return true;
      default:
        return false;
    }
  }
}
