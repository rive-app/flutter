import 'package:flutter/material.dart';

/// Paints a crisp non anti-aliased line with optional dashing.
class TreeLine extends LeafRenderObjectWidget {
  final List<double> dashPattern;
  final Color color;

  TreeLine({
    this.dashPattern,
    this.color = Colors.black,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _TreeLineRenderer()
      ..dashPattern = dashPattern
      ..color = color;
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant _TreeLineRenderer renderObject) {
    renderObject
      ..dashPattern = dashPattern
      ..color = color;
  }
}

class _TreeLineRenderer extends RenderBox {
  final Paint _paint = Paint()
    ..style = PaintingStyle.stroke
    ..isAntiAlias = false;

  List<double> _dashPattern;
  List<double> get dashPattern => _dashPattern;
  set dashPattern(List<double> value) {
    if (_dashPattern == value) {
      return;
    }
    _dashPattern = value;
    markNeedsPaint();
  }

  @override
  bool get sizedByParent => true;

  Color _color;
  Color get color => _color;
  set color(Color value) {
    if (_color == value) {
      return;
    }
    _color = value;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    var canvas = context.canvas;
    bool isHorizontal = size.width > size.height;
    double thickness = isHorizontal ? size.height : size.width;
    double maxOffset = isHorizontal ? size.width : size.height;
    _paint
      ..color = color
      ..strokeWidth = thickness;

    double dashOffset = 0;
    var last = offset;
    if (dashPattern == null) {
      canvas.drawLine(
          last,
          offset +
              Offset(
                  isHorizontal ? maxOffset : 0, isHorizontal ? 0 : maxOffset),
          _paint);
      return;
    }
    int index = 0;
    while (dashOffset < maxOffset) {
      dashOffset += dashPattern[index];
      if (dashOffset > maxOffset) {
        dashOffset = maxOffset;
      }
      var next =
          Offset(isHorizontal ? dashOffset : 0, isHorizontal ? 0 : dashOffset);
      if (index % 2 == 0) {
        canvas.drawLine(last, next, _paint);
      }
      index = (index + 1) % dashPattern.length;
      last = next;
    }
  }
}
