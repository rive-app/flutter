import 'dart:math';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:tree_widget/flat_tree_item.dart';
import 'package:tree_widget/tree_arrow_icon.dart';
import 'package:tree_widget/tree_controller.dart';
import 'package:tree_widget/tree_style.dart';
import 'package:tree_widget/tree_widget.dart';

void main() => runApp(MyApp());

class ExampleTreeView extends StatefulWidget {
  @override
  _ExampleTreeViewState createState() => _ExampleTreeViewState();
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData.dark(),
        home: Scaffold(body: ExampleTreeView()));
  }
}

class MyTreeController extends TreeController<TreeItem> {
  MyTreeController(List<TreeItem> data) : super(data);

  @override
  bool get hasProperties => true;

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
  List<FlatTreeItem<TreeItem>> onDragStart(
      DragStartDetails details, FlatTreeItem<TreeItem> item) {
    return [item];
  }

  @override
  void onMouseEnter(PointerEnterEvent event, FlatTreeItem<TreeItem> item) {
    if (item.data.selectionState.value == SelectionState.selected) {
      return;
    }
    item.data.select(SelectionState.hovered);
  }

  @override
  void onMouseExit(PointerExitEvent event, FlatTreeItem<TreeItem> item) {
    if (item.data.selectionState.value == SelectionState.selected) {
      return;
    }
    item.data.select(SelectionState.none);
  }

  @override
  void onTap(FlatTreeItem<TreeItem> item) {
    item.data.select(item.data.selectionState.value == SelectionState.selected
        ? SelectionState.hovered
        : SelectionState.selected);
  }

  @override
  int spacingOf(TreeItem treeItem) {
    if (treeItem.name == 'leg_left') {
      return 3;
    }
    return treeItem.name != 'eye_happy' && treeItem.parent is SoloTreeItem
        ? 2
        : 1;
  }

  @override
  void drop(FlatTreeItem<TreeItem> target, DropState state,
      List<FlatTreeItem<TreeItem>> items) {
    switch (state) {
      case DropState.above:
        var newParent = target.data.parent;
        var idx = newParent.children.indexOf(target.data);
        for (final item in items) {
          var treeItem = item.data;

          treeItem.parent.children.remove(treeItem);

          treeItem.parent = newParent;
          newParent.children.insert(idx, treeItem);
        }
        break;
      case DropState.below:
        var newParent = target.data.parent;
        var idx = newParent.children.indexOf(target.data) + 1;
        for (final item in items) {
          var treeItem = item.data;

          treeItem.parent.children.remove(treeItem);

          treeItem.parent = newParent;
          newParent.children.insert(idx, treeItem);
        }
        break;
      case DropState.into:
        for (final item in items) {
          var treeItem = item.data;
          treeItem.parent.children.remove(treeItem);
          treeItem.parent = target.data;
          target.data.children.add(treeItem);
        }
        break;
      default:
        break;
    }

    // Force re-flatten the tree (N.B. you should do this when the children
    // change some other way too).
    flatten();
  }
}

class PropertyTreeItem extends TreeItem {
  PropertyTreeItem(String name, {List<TreeItem> children})
      : super(name, children: children);
}

abstract class SelectableItem {
  ValueListenable<SelectionState> get selectionState;
  void select(SelectionState state);
}

enum SelectionState { selected, hovered, none }

class SoloTreeItem extends TreeItem {
  SoloTreeItem(String name, {List<TreeItem> children})
      : super(name, children: children);
}

class TreeExpander extends StatefulWidget {
  final bool isExpanded;

  const TreeExpander({Key key, this.isExpanded}) : super(key: key);
  @override
  _TreeExpanderState createState() {
    // print("CREATING STATE FOR $key");
    return _TreeExpanderState();
  }
}

class TreeItem implements SelectableItem {
  final String name;
  List<TreeItem> children;

  TreeItem parent;

  final ValueNotifier<SelectionState> _selectionState =
      ValueNotifier<SelectionState>(SelectionState.none);

  TreeItem(this.name, {this.children}) {
    children ??= [];
    for (final child in children) {
      child.parent = this;
    }
  }

  @override
  ValueListenable<SelectionState> get selectionState => _selectionState;
  @override
  void select(SelectionState state) {
    _selectionState.value = state;
  }

  @override
  String toString() {
    return name;
  }
}

class _ExampleTreeViewState extends State<ExampleTreeView> {
  MyTreeController _controller;
  @override
  Widget build(BuildContext context) {
    return TreeView<TreeItem>(
      style: TreeStyle(
        padding: const EdgeInsets.all(10),
        lineColor: Colors.grey.shade700,
      ),
      controller: _controller,
      expanderBuilder: (context, item) => Container(
        child: Center(
          child: TreeExpander(
            key: item.key,
            isExpanded: item.isExpanded,
          ),
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey.shade700,
            width: 1.0,
            style: BorderStyle.solid,
          ),
          borderRadius: const BorderRadius.all(
            Radius.circular(7.5),
          ),
        ),
      ),
      iconBuilder: (context, item) => Container(
        decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: const BorderRadius.all(
            Radius.circular(2),
          ),
        ),
      ),
      extraBuilder: (context, item, index) => Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.white,
            width: 1.0,
            style: BorderStyle.solid,
          ),
          borderRadius: const BorderRadius.all(
            Radius.circular(7.5),
          ),
        ),
      ),
      backgroundBuilder: (context, item) => ValueListenableBuilder<DropState>(
        valueListenable: item.dropState,
        builder: (context, dropState, _) =>
            ValueListenableBuilder<SelectionState>(
          builder: (context, selectionState, _) {
            return background(dropState, selectionState);
          },
          valueListenable: item.data.selectionState,
        ),
      ),
      itemBuilder: (context, item) => ValueListenableBuilder<SelectionState>(
        builder: (context, state, _) => Expanded(
          child: Row(
            children: [
              Expanded(
                child: IgnorePointer(
                  child: Text(
                    item.data.name,
                    style: TextStyle(
                      fontFamily: 'Roboto-Regular',
                      fontSize: 13,
                      color: state == SelectionState.selected
                          ? Colors.white
                          : Colors.grey.shade500,
                    ),
                  ),
                ),
              ),
              Text(
                "lock",
                style: TextStyle(
                  fontFamily: 'Roboto-Regular',
                  fontSize: 13,
                  color: state == SelectionState.selected
                      ? Colors.white
                      : Colors.grey.shade500,
                ),
              ),
              const SizedBox(width: 5)
            ],
          ),
        ),
        valueListenable: item.data.selectionState,
      ),
    );
  }

  Widget background(DropState dropState, SelectionState selectionState) {
    switch (dropState) {
      case DropState.parent:
        return Padding(
          padding: const EdgeInsets.all(2),
          child: DottedBorder(
            color: const Color.fromRGBO(87, 165, 224, 1.0),
            strokeWidth: 2,
            borderType: BorderType.RRect,
            dashPattern: const [7, 5],
            radius: const Radius.circular(5),
            child: Container(),
          ),
        );
      case DropState.above:
        return Container(
          clipBehavior: Clip.none,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Color.fromRGBO(87, 165, 224, 1.0),
                width: 2.0,
                style: BorderStyle.solid,
              ),
            ),
          ),
        );
      case DropState.below:
        return Transform.translate(
          offset: const Offset(0, 2),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color.fromRGBO(87, 165, 224, 1.0),
                  width: 2.0,
                  style: BorderStyle.solid,
                ),
              ),
            ),
          ),
        );
      case DropState.into:
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color.fromRGBO(87, 165, 224, 1.0),
              width: 2.0,
              style: BorderStyle.solid,
            ),
            borderRadius: const BorderRadius.all(
              Radius.circular(5.0),
            ),
          ),
        );
      case DropState.none:
        switch (selectionState) {
          case SelectionState.hovered:
            return Container(
              decoration: const BoxDecoration(
                color: Color.fromRGBO(87, 165, 224, 0.3),
                borderRadius: BorderRadius.all(
                  Radius.circular(5.0),
                ),
              ),
            );
          case SelectionState.selected:
            return Container(
              decoration: const BoxDecoration(
                color: Color.fromRGBO(87, 165, 224, 1.0),
                borderRadius: BorderRadius.all(
                  Radius.circular(5.0),
                ),
              ),
            );
          case SelectionState.none:
            break;
        }
        break;
    }

    return Container(color: Colors.transparent);
  }

  @override
  void initState() {
    super.initState();
    var data = [
      TreeItem(
        "Artboard",
        children: [
          TreeItem(
            "Group",
            children: [
              TreeItem("body"),
              TreeItem("neck"),
              TreeItem("leg_right"),
              TreeItem("head"),
              TreeItem("leg_left", children: [
                TreeItem("one", children: [
                  PropertyTreeItem("Translation Constraint"),
                ]),
                TreeItem("ik_head", children: [
                  PropertyTreeItem("Translation Constraint"),
                  TreeItem("neck"),
                  TreeItem("leg_left", children: [
                    TreeItem("one"),
                    TreeItem("ik_head", children: [
                      PropertyTreeItem("Translation Constraint"),
                      TreeItem("neck"),
                    ]),
                    TreeItem("two"),
                    TreeItem("three"),
                  ]),
                ]),
                TreeItem("two"),
                TreeItem("three"),
              ]),
              TreeItem("root", children: [
                TreeItem("ik_head", children: [
                  PropertyTreeItem("Translation Constraint"),
                  TreeItem("neck"),
                ]),
                TreeItem("ctrl_foot_left"),
                TreeItem("ctrl_foot_right"),
              ]),
              TreeItem("leg_left"),
              SoloTreeItem("eyes", children: [
                TreeItem("eye_normal"),
                TreeItem("eye_angry"),
                TreeItem("eye_happy", children: [
                  PropertyTreeItem("Translation Constraint"),
                  TreeItem("something"),
                  TreeItem("something2"),
                ]),
                TreeItem("eye_other", children: [
                  PropertyTreeItem("Translation Constraint"),
                  TreeItem("something"),
                  TreeItem("something2"),
                  SoloTreeItem("sub_eyes", children: [
                    TreeItem("eye_normal"),
                    TreeItem("eye_angry"),
                    TreeItem("eye_happy", children: [
                      PropertyTreeItem("Translation Constraint"),
                      PropertyTreeItem("Rotation Constraint"),
                      TreeItem("something"),
                      TreeItem("something2"),
                    ]),
                    TreeItem("eye_other", children: [
                      PropertyTreeItem("Translation Constraint"),
                      TreeItem("something"),
                      TreeItem("something2"),
                    ]),
                    TreeItem("ctrl_foot_left"),
                    TreeItem("ctrl_foot_right"),
                  ]),
                ]),
                TreeItem("ctrl_foot_left"),
                TreeItem("ctrl_foot_right"),
              ]),
              TreeItem("leg_right"),
            ],
          ),
        ],
      )
    ];
    _controller = MyTreeController(data);
    _controller.expand(data[0]);
    _controller.expand(data[0].children[0]);
    _controller.expand(data[0].children[0].children[5]);
  }
}

class _TreeExpanderState extends State<TreeExpander>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: CustomPaint(
        painter: TreeArrowIcon(color: Colors.white),
      ),
      builder: (BuildContext context, Widget child) {
        return Transform.rotate(
          angle: -Curves.easeInOut.transform(_controller.value) * pi / 2,
          child: child,
        );
      },
    );
  }

  @override
  void didUpdateWidget(TreeExpander oldWidget) {
    // print("UPDATE EXPANDER ${widget.key}");
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isExpanded == widget.isExpanded) {
      return;
    }
    if (widget.isExpanded) {
      _controller.reverse(from: 1);
    } else {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    // print("INIT EXPANDER ${widget.key}");

    if (widget.isExpanded) {
      _controller.value = 0;
    } else {
      _controller.value = 1;
    }
  }
}
