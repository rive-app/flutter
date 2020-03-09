import 'package:flutter/material.dart';

/// Paints a crisp non anti-aliased arrow line.
class TreeArrowIcon extends CustomPainter {
  final Color color;
  final StrokeCap strokeCap;
  final double thickness;

  TreeArrowIcon(
      {this.color = Colors.black,
      this.strokeCap = StrokeCap.square,
      this.thickness = 1});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..isAntiAlias = true;

  double scale = 1.0;
    var path = Path();
    path.moveTo(-2*scale, -1*scale);
    path.lineTo(0, 1*scale);
    path.lineTo(2*scale, -1*scale);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(TreeArrowIcon oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeCap != strokeCap ||
        oldDelegate.thickness != thickness;
  }
}
