import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:tree_widget/flat_tree_item.dart';
import 'package:tree_widget/tree_controller.dart';

import 'folder.dart';

class FolderTreeController extends TreeController<FolderItem> {
  final Rive rive;
  FolderTreeController(List<FolderItem> data, {this.rive}) : super(data);

  @override
  List<FolderItem> childrenOf(FolderItem treeItem) =>
      treeItem is FolderItem ? treeItem.folders : null;

  @override
  void drop(FlatTreeItem<FolderItem> target, DropState state,
      List<FlatTreeItem<FolderItem>> items) {}

  @override
  bool isDisabled(FolderItem treeItem) {
    return false;
  }

  @override
  bool isProperty(FolderItem treeItem) {
    return false;
  }

  @override
  List<FlatTreeItem<FolderItem>> onDragStart(
      DragStartDetails details, FlatTreeItem<FolderItem> item) {
    return [item];
  }

  @override
  void onMouseEnter(PointerEnterEvent event, FlatTreeItem<FolderItem> item) {
    item.data.isHovered = true;
  }

  @override
  void onMouseExit(PointerExitEvent event, FlatTreeItem<FolderItem> item) {
    item.data.isHovered = false;
  }

  @override
  void onTap(FlatTreeItem<FolderItem> item) {
    if (item.data != null) {
      if (rive.fileBrowser.currentFolder.key == item.data.key) {
        rive.fileBrowser.selectItem(rive, item.data);
      } else {
        rive.fileBrowser.openFolder(item.data, false);
      }
      // rive.fileBrowser.selectItem(rive, item.data);
    }
  }

  @override
  int spacingOf(FolderItem treeItem) {
    return 1;
  }
}
