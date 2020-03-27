import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:tree_widget/flat_tree_item.dart';
import 'package:tree_widget/tree_controller.dart';

import '../rive.dart';
import 'rive_folder.dart';

/// TreeController for the Rive folders displayed in the FileBrowser screen.
class FolderTreeController extends TreeController<RiveFolder> {
  final Rive rive;
  final List<RiveFolder> data;
  FolderTreeController(this.data, {this.rive})
      : super(data);

  @override
  List<RiveFolder> childrenOf(RiveFolder treeItem) =>
      treeItem.children.cast<RiveFolder>();

  @override
  void drop(FlatTreeItem<RiveFolder> target, DropState state,
      List<FlatTreeItem<RiveFolder>> items) {}

  @override
  bool isDisabled(RiveFolder treeItem) {
    return false;
  }

  @override
  bool isProperty(RiveFolder treeItem) {
    return false;
  }

  @override
  List<FlatTreeItem<RiveFolder>> onDragStart(
      DragStartDetails details, FlatTreeItem<RiveFolder> item) {
    return [item];
  }

  @override
  void onMouseEnter(PointerEnterEvent event, FlatTreeItem<RiveFolder> item) {
    item.data.isHovered = true;
  }

  @override
  void onMouseExit(PointerExitEvent event, FlatTreeItem<RiveFolder> item) {
    item.data.isHovered = false;
  }

  @override
  void onTap(FlatTreeItem<RiveFolder> item) {
    if (item.data != null) {
      rive.fileBrowser.openFolder(item.data, false);
    }
  }

  @override
  int spacingOf(RiveFolder treeItem) {
    return 1;
  }
}
