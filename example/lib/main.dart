import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tree_widget/tree_widget.dart';
import 'package:tree_widget/tree_arrow_icon.dart';

void main() => runApp(MyApp());

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

class ExampleTreeView extends StatefulWidget {
  @override
  _ExampleTreeViewState createState() => _ExampleTreeViewState();
}

enum SelectionState { selected, hovered, none }

abstract class SelectableItem {
  ValueListenable<SelectionState> get selectionState;
  void select(SelectionState state);
}

class TreeItem implements SelectableItem {
  final String name;
  final List<TreeItem> children;
  TreeItem parent;

  @override
  String toString() {
    return name;
  }

  TreeItem(this.name, {this.children}) {
    if (children == null) {
      return;
    }
    for (final child in children) {
      child.parent = this;
    }
  }

  @override
  ValueListenable<SelectionState> get selectionState => _selectionState;
  final ValueNotifier<SelectionState> _selectionState =
      ValueNotifier<SelectionState>(SelectionState.none);

  @override
  void select(SelectionState state) {
    _selectionState.value = state;
  }
}

class SoloTreeItem extends TreeItem {
  SoloTreeItem(String name, {List<TreeItem> children})
      : super(name, children: children);
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
    if (treeItem.name == 'leg_left') {
      return 3;
    }
    return treeItem.name != 'eye_happy' && treeItem.parent is SoloTreeItem
        ? 2
        : 1;
  }

  @override
  bool get hasProperties => true;
}

class _ExampleTreeViewState extends State<ExampleTreeView> {
  MyTreeController _controller;
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
                TreeItem("one"),
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

  @override
  Widget build(BuildContext context) {
    return TreeView<TreeItem>(
      padding: const EdgeInsets.all(10),
      lineColor: Colors.white30,
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
            color: Colors.white30,
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
      backgroundBuilder: (context, item, offset) =>
          ValueListenableBuilder<SelectionState>(
        builder: (context, state, _) => Positioned(
          left: offset,
          top: 0,
          bottom: 0,
          right: 0,
          child: MouseRegion(
            onEnter: (event) {
              if (item.data.selectionState.value == SelectionState.selected) {
                return;
              }
              item.data.select(SelectionState.hovered);
            },
            onExit: (event) {
              if (item.data.selectionState.value == SelectionState.selected) {
                return;
              }
              item.data.select(SelectionState.none);
            },
            child: GestureDetector(
              onTap: () {
                item.data.select(
                    item.data.selectionState.value == SelectionState.selected
                        ? SelectionState.hovered
                        : SelectionState.selected);
              },
              onVerticalDragStart: (details) {
                _controller.startDrag([item]);
                print("START DRAG ${details.globalPosition}");
              },
              onVerticalDragEnd: (details) {
                print("END DRAG");
                _controller.stopDrag();
              },
              onVerticalDragUpdate: (details) {
                //print("UPDATE DRAG ${details.globalPosition}");
                
              },
              child: Container(
                color: item.data.selectionState.value == SelectionState.none
                    ? Colors.transparent
                    : null,
                decoration:
                    item.data.selectionState.value != SelectionState.none
                        ? BoxDecoration(
                            color: item.data.selectionState.value ==
                                    SelectionState.hovered
                                ? const Color.fromRGBO(87, 165, 224, 0.3)
                                : const Color.fromRGBO(87, 165, 224, 1.0),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(5.0),
                            ),
                          )
                        : null,
              ),
            ),
          ),
        ),
        valueListenable: item.data.selectionState,
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
                        fontFamily: 'RobotoRegular',
                        fontSize: 13,
                        color: state == SelectionState.selected
                            ? Colors.white
                            : Colors.white54),
                  ),
                ),
              ),
              Text(
                "lock",
                style: TextStyle(
                    fontFamily: 'RobotoRegular',
                    fontSize: 13,
                    color: state == SelectionState.selected
                        ? Colors.white
                        : Colors.white54),
              ),
              const SizedBox(width: 5)
            ],
          ),
        ),
        valueListenable: item.data.selectionState,
      ),
    );
  }
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

class _TreeExpanderState extends State<TreeExpander>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;

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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
}
