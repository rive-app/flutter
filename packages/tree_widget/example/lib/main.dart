import 'dart:math';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:tree_widget/flat_tree_item.dart';
import 'package:tree_widget/tree_arrow_icon.dart';
import 'package:tree_widget/tree_line.dart';
import 'package:tree_widget/tree_style.dart';
import 'package:tree_widget/tree_widget.dart';

import 'my_tree_controller.dart';
import 'tree_item.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData.dark(),
      home: Scaffold(
        body: ExampleTreeView(),
      ),
    );
  }
}

/// An example tree view, shows how to implement TreeView widget and style it.
class ExampleTreeView extends StatefulWidget {
  @override
  _ExampleTreeViewState createState() => _ExampleTreeViewState();
}

class _ExampleTreeViewState extends State<ExampleTreeView> {
  /// TreeView controller which handles things like expanding items, responding
  /// to whether drag/drop is allowed for a specific item, etc.
  MyTreeController _controller;

  /// Callback for creating the background of a tree row. This has some special
  /// state management for conditions like allowing dropping above/below/into an
  /// item. The TreeView is specifically built to allow theming all aspects,
  /// including stylings for drag and drop.
  Widget itemBackground(DropState dropState, SelectionState selectionState) {
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
  Widget build(BuildContext context) {
    var treeStyle = TreeStyle(
        padding: const EdgeInsets.all(20),
        lineColor: Colors.grey.shade700,
        showFirstLine: false);
    return TreeView<TreeItem>(
      style: treeStyle,
      controller: _controller,
      separatorBuilder: (context, index) => Stack(
        children: [
          Positioned(
            left: 0,
            top: treeStyle.itemHeight/2-1,
            bottom: treeStyle.itemHeight/2,
            right: 0,
            child: Container(
              child: CustomPaint(
                painter: TreeLine(
                  color: treeStyle.lineColor,
                  strokeCap: StrokeCap.butt,
                ),
              ),
            ),
          ),
        ],
      ),
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
            return itemBackground(dropState, selectionState);
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

  @override
  void initState() {
    super.initState();

    // Just some test data...
    var data = [
      TreeItem(
        "Artboard 1",
        children: [
          TreeItem(
            "Group Test",
            children: [
              TreeItem("body"),
              TreeItem("neck"),
              TreeItem("leg_right"),
              TreeItem("head"),
            ],
          ),
        ],
      ),
      TreeItem(
        "Artboard2",
      ),
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
    _controller.flatten();
    // Programmatically expand some items in the tree
    _controller.expand(data[0]);
    _controller.expand(data[1]);
    // _controller.expand(data[0].children[0]);
    // _controller.expand(data[0].children[0].children[5]);
  }
}

/// Widget used to draw a circular expansion arrow for items in the tree that
/// can be opened to reveal more content.
class TreeExpander extends StatefulWidget {
  final bool isExpanded;

  const TreeExpander({Key key, this.isExpanded}) : super(key: key);
  @override
  _TreeExpanderState createState() {
    return _TreeExpanderState();
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

    if (widget.isExpanded) {
      _controller.value = 0;
    } else {
      _controller.value = 1;
    }
  }
}
