import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class InspectorPopoutPositioner extends StatelessWidget {
  final double right;
  final double top;
  final double width;
  final Widget child;

  const InspectorPopoutPositioner({
    Key key,
    this.right,
    this.top,
    this.width,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomSingleChildLayout(
      child: child,
      delegate: _PopupPositionerDelegate(right, top, width),
    );
  }
}

class _PopupPositionerDelegate extends SingleChildLayoutDelegate {
  final double right;
  final double top;
  final double width;

  /// How much space to leave on the bottom of the screen. Prevents the popup
  /// from pressing right up to the edge.
  static const double _screenEdgeMargin = 10;

  _PopupPositionerDelegate(this.right, this.top, this.width);

  @override
  bool shouldRelayout(_PopupPositionerDelegate oldDelegate) {
    return oldDelegate.width != width ||
        oldDelegate.right != right ||
        oldDelegate.top != top;
  }

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints(
      maxWidth: width,
      minWidth: width,
      maxHeight: constraints.maxHeight,
      minHeight: 0,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    double y = top;
    double x = size.width - right - childSize.width;
    if (y != null && y + childSize.height + _screenEdgeMargin > size.height) {
      y -= y + childSize.height - size.height + _screenEdgeMargin;
    }

    return Offset(x, y);
  }
}
