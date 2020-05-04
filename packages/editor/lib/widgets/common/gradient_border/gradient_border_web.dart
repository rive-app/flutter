import 'package:flutter/widgets.dart';

void paintGradientBorder(
  Canvas canvas,
  Paint paint,
  Size size,
  double strokeWidth,
  double radius,
  Gradient gradient,
) {
  // create outer rectangle equals size
  final outerRect = Offset.zero & size;
  final outerRRect =
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));

  paint
    // ..shader = gradient.createShader(outerRect)
    ..color = gradient.colors.first
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth;
  Path path = Path()..addRRect(outerRRect);
  canvas.drawPath(path, paint);
}
