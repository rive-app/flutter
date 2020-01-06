import 'package:flutter/src/gestures/drag_details.dart';
import 'package:flutter/src/gestures/events.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tree_widget/flat_tree_item.dart';
import 'package:tree_widget/tree_controller.dart';

class TreeItem {
  final String name;
  final List<TreeItem> children;

  TreeItem(this.name, {this.children});
}

class PropertyTreeItem extends TreeItem {
  PropertyTreeItem(String name, {List<TreeItem> children})
      : super(name, children: children);
}

class MyTreeController extends TreeController<TreeItem> {
  MyTreeController(List<TreeItem> data) : super(data);

  @override
  List<TreeItem> childrenOf(TreeItem treeItem) {
    return treeItem.children;
  }

  @override
  bool isDisabled(TreeItem treeItem) {
    return false;
  }

  @override
  bool isProperty(TreeItem treeItem) {
    return treeItem is PropertyTreeItem;
  }

  @override
  int spacingOf(TreeItem treeItem) {
    return 1;
  }

  @override
  void drop(FlatTreeItem<TreeItem> target, DropState state,
      List<FlatTreeItem<TreeItem>> items) {}

  @override
  List<FlatTreeItem<TreeItem>> onDragStart(
      DragStartDetails details, FlatTreeItem<TreeItem> item) {
    return [];
  }

  @override
  void onMouseEnter(PointerEnterEvent event, FlatTreeItem<TreeItem> item) {}

  @override
  void onMouseExit(PointerExitEvent event, FlatTreeItem<TreeItem> item) {}

  @override
  void onTap(FlatTreeItem<TreeItem> item) {}
}

void main() {
  test('test tree flattening', () {
    var data = [
      TreeItem(
        "Artboard",
        children: [
          TreeItem("Group"),
          TreeItem("body"),
          TreeItem("neck"),
          TreeItem("leg_right"),
          TreeItem("head"),
          TreeItem("leg_left"),
          TreeItem("root", children: [
            TreeItem("ik_head", children: [
              PropertyTreeItem("Translation Constraint"),
              TreeItem("neck"),
            ]),
            TreeItem("ctrl_foot_left"),
            TreeItem("ctrl_foot_right"),
          ]),
          TreeItem("leg_left"),
          TreeItem("leg_right"),
        ],
      )
    ];

    var controller = MyTreeController(data);
    controller.flatten();
    controller.expand(data[0]);
    controller.expand(data[0].children[6]);
    expect(controller.flat.length, 13);
  });
}
