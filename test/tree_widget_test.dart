import 'package:flutter_test/flutter_test.dart';

import 'package:tree_widget/tree_widget.dart';

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
    // ..expanded = <TreeItem>{tree, tree.children[6]};
    controller.expand(data[0]);
    controller.expand(data[0].children[6]);
    expect(controller.flat.length, 13);
    // final calculator = Calculator();
    // expect(calculator.addOne(2), 3);
    // expect(calculator.addOne(-7), -6);
    // expect(calculator.addOne(0), 1);
    // expect(() => calculator.addOne(null), throwsNoSuchMethodError);
  });
}
