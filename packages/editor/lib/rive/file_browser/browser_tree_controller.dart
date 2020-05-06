import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:tree_widget/flat_tree_item.dart';
import 'package:tree_widget/tree_controller.dart';

import 'package:rive_editor/rive/file_browser/file_browser.dart';
import 'package:rive_editor/rive/file_browser/rive_folder.dart';
import 'package:rive_editor/rive/rive.dart';

import 'package:rive_api/src/model/model.dart';

/// TreeController for the Rive folders displayed in the FileBrowser screen.
class FolderTreeController extends TreeController<RiveFolder> {
  List<RiveFolder> _data;
  final Rive rive;
  final FileBrowser fileBrowser;
  FolderTreeController(this._data, {this.fileBrowser, this.rive}) : super();

  @override
  Iterable<RiveFolder> get data => _data;

  set data(Iterable<RiveFolder> value) {
    _data = value.toList();
    refreshExpanded();
  }

  @override
  Iterable<RiveFolder> childrenOf(RiveFolder treeItem) =>
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
        rive.setActiveFileBrowser(fileBrowser);
      }

      fileBrowser.openFolder(item.data, false);
    }
  }

  @override
  int spacingOf(RiveFolder treeItem) {
    return 1;
  }

  @override
  void onRightClick(BuildContext context, PointerDownEvent event,
      FlatTreeItem<RiveFolder> item) {}
}

class FolderTreeItemController extends TreeController<FolderTreeItem> {
  List<FolderTreeItem> _data;
  FolderTreeItemController(FolderTree folderTree)
      : _data = [folderTree.root],
        super();

  @override
  Iterable<FolderTreeItem> get data => _data;

  set data(Iterable<FolderTreeItem> value) {
    _data = value.toList();
    refreshExpanded();
  }

  @override
  Iterable<FolderTreeItem> childrenOf(FolderTreeItem treeItem) =>
      treeItem.children.cast<FolderTreeItem>();

  @override
  void drop(FlatTreeItem<FolderTreeItem> target, DropState state,
      List<FlatTreeItem<FolderTreeItem>> items) {}

  @override
  dynamic dataKey(FolderTreeItem treeItem) {
    return treeItem.folder.id;
  }

  @override
  bool isDisabled(FolderTreeItem treeItem) {
    return false;
  }

  @override
  bool isProperty(FolderTreeItem treeItem) {
    return false;
  }

  @override
  List<FlatTreeItem<FolderTreeItem>> onDragStart(
      DragStartDetails details, FlatTreeItem<FolderTreeItem> item) {
    return [item];
  }

  @override
  void onMouseEnter(
      PointerEnterEvent event, FlatTreeItem<FolderTreeItem> item) {
    print('hover on $item');
  }

  @override
  void onMouseExit(PointerExitEvent event, FlatTreeItem<FolderTreeItem> item) {
    print('hover off $item');
  }

  @override
  void onTap(FlatTreeItem<FolderTreeItem> item) {
    print('tipper tapper $item');
  }

  @override
  int spacingOf(FolderTreeItem treeItem) {
    return 1;
  }

  @override
  void onRightClick(BuildContext context, PointerDownEvent event,
      FlatTreeItem<FolderTreeItem> item) {}
}
