import 'package:flutter/gestures.dart';

import 'package:rive_core/artboard.dart';
import 'package:rive_core/component.dart';
import 'package:rive_editor/rive/open_file_context.dart';

import 'package:tree_widget/flat_tree_item.dart';
import 'package:tree_widget/tree_controller.dart';

import 'stage/stage_item.dart';

/// Tree Controller for the draw order, requires rive context in order to
/// propagate selections.
class DrawOrderTreeController extends TreeController<Component> {
  final OpenFileContext file;
  DrawOrderTreeController(List<Component> components, {this.file})
      : super(components);

  @override
  List<Component> childrenOf(Component treeItem) => treeItem is Artboard
      ? treeItem.children
          // We only want to show items in the tree which are selectable, in
          // order to be selectable they must have a stageItem.
          .where((item) => item.stageItem != null)
          .toList(growable: false)
      : null;

  @override
  bool isDisabled(Component treeItem) => true;

  @override
  bool isProperty(Component treeItem) => false;

  @override
  void onMouseEnter(PointerEnterEvent event, FlatTreeItem<Component> item) =>
      item.data.stageItem.isHovered = true;

  @override
  void onMouseExit(PointerExitEvent event, FlatTreeItem<Component> item) =>
      item.data.stageItem.isHovered = false;

  @override
  void onTap(FlatTreeItem<Component> item) {
    if (item.data.stageItem != null) {
      file.select(item.data.stageItem);
    }
  }

  @override
  int spacingOf(Component treeItem) => 1;

  @override
  void drop(FlatTreeItem<Component> target, DropState state,
      List<FlatTreeItem<Component>> items) {
    // TODO: implement drop
  }

  @override
  List<FlatTreeItem<Component>> onDragStart(
      DragStartDetails details, FlatTreeItem<Component> item) {
    return [];
  }
}
