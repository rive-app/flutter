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

  // create inner rectangle smaller by strokeWidth
  final innerRect = Rect.fromLTWH(strokeWidth, strokeWidth,
      size.width - strokeWidth * 2, size.height - strokeWidth * 2);
  final innerRRect =
      RRect.fromRectAndRadius(innerRect, Radius.circular(radius - strokeWidth));

  // apply gradient shader
  paint.shader = gradient.createShader(outerRect);

  // create difference between outer and inner paths and draw it
  canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRRect(outerRRect),
        Path()..addRRect(innerRRect),
      ),
      paint);
}
