import 'package:flutter/material.dart';

/// Draws a thin separating line of [color] width [padding].
class Separator extends LeafRenderObjectWidget {
  final Color color;
  final EdgeInsets padding;

  const Separator({
    @required this.color,
    this.padding = EdgeInsets.zero,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return SeparatorRenderObject()
      ..color = color
      ..padding = padding;
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant SeparatorRenderObject renderObject) {
    renderObject
      ..color = color
      ..padding = padding;
  }
}

class SeparatorRenderObject extends RenderBox {
  static const double lineHeight = 1;

  EdgeInsets _padding;
  Color _color;
  final Paint _paint = Paint()..isAntiAlias = false;

  EdgeInsets get padding => _padding;

  set padding(EdgeInsets value) {
    if (_padding == value) {
      return;
    }
    _padding = value;
    markNeedsLayout();
  }

  Color get color => _color;

  set color(Color value) {
    if (_color == value) {
      return;
    }
    _color = value;
    _paint.color = value;
    markNeedsPaint();
  }

  @override
  bool get sizedByParent => false;

  @override
  double computeMinIntrinsicWidth(double height) =>
      _padding.left + _padding.right;

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _padding.left + _padding.right;

  @override
  double computeMinIntrinsicHeight(double width) =>
      _padding.top + lineHeight + _padding.bottom;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _padding.top + lineHeight + _padding.bottom;

  @override
  void performLayout() {
    final BoxConstraints constraints = this.constraints;
    size = constraints.constrain(Size(
      _padding.left + _padding.right,
      _padding.top + lineHeight + _padding.bottom,
    ));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    context.canvas.drawRect(
        Rect.fromLTWH(offset.dx + _padding.left, offset.dy + _padding.top,
            size.width - padding.horizontal, lineHeight),
        _paint);
  }
}
