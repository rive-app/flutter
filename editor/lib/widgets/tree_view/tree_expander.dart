import 'package:flutter/material.dart';
import 'package:tree_widget/tree_arrow_icon.dart';
import 'dart:math';

/// Widget used to draw a circular expansion arrow for items in the tree that
/// can be opened to reveal more content.
class TreeExpander extends StatefulWidget {
  final bool isExpanded;
  final Color iconColor;

  const TreeExpander({
    Key key,
    @required this.isExpanded,
    @required this.iconColor,
  }) : super(key: key);
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
        painter: TreeArrowIcon(color: widget.iconColor),
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
