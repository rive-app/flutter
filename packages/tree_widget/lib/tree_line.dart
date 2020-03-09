import 'package:flutter/material.dart';

/// Paints a crisp non anti-aliased line with optional dashing.
class TreeLine extends CustomPainter {
  final List<double> dashPattern;
  final Color color;
  final StrokeCap strokeCap;

  TreeLine(
      {this.dashPattern,
      this.color = Colors.black,
      this.strokeCap = StrokeCap.square});

  @override
  void paint(Canvas canvas, Size size) {
    bool isHorizontal = size.width > size.height;
    double thickness = isHorizontal ? size.height : size.width;
    double maxOffset = isHorizontal ? size.width : size.height;
    var paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..isAntiAlias = false;

    double offset = 0;
    var last = Offset.zero;
    if (dashPattern == null) {
      canvas.drawLine(
          last,
          Offset(isHorizontal ? maxOffset : 0, isHorizontal ? 0 : maxOffset),
          paint);
      return;
    }
    int index = 0;
    while (offset < maxOffset) {
      offset += dashPattern[index];
      if (offset > maxOffset) {
        offset = maxOffset;
      }
      var next = Offset(isHorizontal ? offset : 0, isHorizontal ? 0 : offset);
      if (index % 2 == 0) {
        canvas.drawLine(last, next, paint);
      }
      index = (index + 1) % dashPattern.length;
      last = next;
    }
  }

  @override
  bool shouldRepaint(TreeLine oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.dashPattern != dashPattern ||
        oldDelegate.strokeCap != strokeCap;
  }
}
