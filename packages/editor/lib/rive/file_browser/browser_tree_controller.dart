import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:tree_widget/flat_tree_item.dart';
import 'package:tree_widget/tree_controller.dart';

import 'package:rive_editor/rive/file_browser/file_browser.dart';
import 'package:rive_editor/rive/file_browser/rive_folder.dart';
import 'package:rive_editor/rive/rive.dart';

/// TreeController for the Rive folders displayed in the FileBrowser screen.
class FolderTreeController extends TreeController<RiveFolder> {
  final List<RiveFolder> data;
  final Rive rive;
  final FileBrowser fileBrowser;
  FolderTreeController(this.data, {this.fileBrowser, this.rive}) : super(data);

  @override
  List<RiveFolder> childrenOf(RiveFolder treeItem) =>
      treeItem.children.cast<RiveFolder>();

  @override
  void drop(FlatTreeItem<RiveFolder> target, DropState state,
      List<FlatTreeItem<RiveFolder>> items) {}

  @override
  dynamic dataKey(RiveFolder treeItem) {
    return treeItem.id;
  }

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
      if (rive.activeFileBrowser.value != fileBrowser) {
        // File browsers track their own selected states.
        // so you have to tell them specifically that stuff not selected
        rive.activeFileBrowser.value?.openFolder(null, false);
        rive.activeFileBrowser.value = fileBrowser;
      }

      fileBrowser.openFolder(item.data, false);
    }
  }

  @override
  int spacingOf(RiveFolder treeItem) {
    return 1;
  }
}
