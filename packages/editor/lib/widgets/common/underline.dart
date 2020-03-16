import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Highly specific Rive widget for underlines.
///
/// Because these are used a lot, we exclusively parameterize only the values
/// that will change at runtime. Values that are static (like the height of the
/// underline) are not exposed. This widget saves us from wrapping things in
/// Containers with Padding and BoxDecorations which create multile
/// RenderObjects. A single view in Rive can have 30+ of these on screen at a
/// single time, so we simplify and optimize with this single render object
/// widget.
class Underline extends SingleChildRenderObjectWidget {
  final Color color;

  const Underline({
    Key key,
    this.color = const Color(0xFFFFFFFF),
    Widget child,
  }) : super(
          key: key,
          child: child,
        );

  @override
  _RenderUnderline createRenderObject(BuildContext context) {
    return _RenderUnderline(color: color);
  }

  @override
  void updateRenderObject(BuildContext context, _RenderUnderline renderObject) {
    renderObject.color = color;
  }
}

class _RenderUnderline extends RenderShiftedBox {
  _RenderUnderline({
    RenderBox child,
    Color color,
  })  : _color = color,
        super(child) {
    _paint.color = color;
  }

  static const double lineHeight = 2;
  static const double offset = 3;
  static const double totalOffset = offset + lineHeight;

  Color _color;
  final Paint _paint = Paint()..style = PaintingStyle.fill;

  Color get color => _color;
  set color(Color value) {
    if (_color == value) {
      return;
    }
    _color = value;
    _paint.color = color;
    markNeedsPaint();
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    if (child != null) {
      return child.getMinIntrinsicHeight(max(0, width)) + totalOffset;
    }
    return offset;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    if (child != null) {
      return child.getMaxIntrinsicHeight(max(0, width)) + totalOffset;
    }
    return totalOffset;
  }

  @override
  void performLayout() {
    final BoxConstraints constraints = this.constraints;
    if (child == null) {
      size = constraints.constrain(const Size(
        0,
        totalOffset,
      ));
      return;
    }

    final double deflatedMinHeight =
        max(0.0, constraints.minHeight - totalOffset);

    final BoxConstraints innerConstraints = BoxConstraints(
      minWidth: constraints.minWidth,
      maxWidth: constraints.maxWidth,
      minHeight: deflatedMinHeight,
      maxHeight: max(deflatedMinHeight, constraints.maxHeight - totalOffset),
    );

    child.layout(innerConstraints, parentUsesSize: true);
    final BoxParentData childParentData = child.parentData as BoxParentData;
    childParentData.offset = const Offset(0, 0);
    size = constraints.constrain(Size(
      child.size.width,
      child.size.height + totalOffset,
    ));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    context.canvas.drawRect(
        Rect.fromLTWH(offset.dx, offset.dy + size.height - lineHeight,
            size.width, lineHeight),
        _paint);
  }
}
