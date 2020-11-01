import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:tree_widget/flat_tree_item.dart';
import 'package:tree_widget/tree_controller.dart';

import 'package:rive_api/plumber.dart';
import 'package:rive_api/model.dart';

class FolderTreeItemController extends TreeController<FolderTreeItem> {
  List<FolderTreeItem> _data;
  FolderTreeItemController(FolderTree folderTree)
      : _data = [folderTree.root],
        super();

  @override
  Iterable<FolderTreeItem> get data => _data;

  Owner get owner => items.first.owner;

  set data(Iterable<FolderTreeItem> value) {
    _data = value.toList();
    refreshExpanded();
  }

  @override
  Iterable<FolderTreeItem> childrenOf(FolderTreeItem treeItem) =>
      treeItem.children.toList(growable: false);

  @override
  void drop(TreeDragOperationTarget<FolderTreeItem> target,
      List<FlatTreeItem<FolderTreeItem>> items) {}

  @override
  dynamic dataKey(FolderTreeItem treeItem) {
    return treeItem.folder?.id;
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
    item.data.hover = true;
  }

  @override
  void onMouseExit(PointerExitEvent event, FlatTreeItem<FolderTreeItem> item) {
    item.data.hover = false;
  }

  void select(CurrentDirectory currentDirectory) {
    items.forEach((element) {
      if (currentDirectory == null) {
        element.selected = false;
      } else if (_data.first.owner == currentDirectory.owner &&
          element.folder?.id == currentDirectory.folder?.id) {
        element.selected = true;
      } else {
        element.selected = false;
      }
    });
  }

  @override
  void onTap(FlatTreeItem<FolderTreeItem> item) {
    final selectedFolder =
        CurrentDirectory(_data.first.owner, item.data.folder);
    Plumber().message<CurrentDirectory>(selectedFolder);
  }

  @override
  int spacingOf(FolderTreeItem treeItem) {
    return 1;
  }

  @override
  void onRightClick(BuildContext context, PointerDownEvent event,
      FlatTreeItem<FolderTreeItem> item) {}

  Iterable<FolderTreeItem> get items sync* {
    if (_data.isNotEmpty) {
      var stack = [_data.first];
      FolderTreeItem tmpElement;
      while (stack.isNotEmpty) {
        tmpElement = stack.removeLast();
        stack.addAll(tmpElement.children);
        yield tmpElement;
      }
    }
  }
}
