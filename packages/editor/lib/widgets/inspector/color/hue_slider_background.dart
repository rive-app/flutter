
import 'package:flutter/material.dart';

/// Background for the Hue slider.
class HueSliderBackground extends CustomPainter {
  const HueSliderBackground();

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect,
        const Radius.circular(8),
      ),
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xffff0000),
            Color(0xffffff00),
            Color(0xff00ff00),
            Color(0xff00ffff),
            Color(0xff0000ff),
            Color(0xffff00ff),
            Color(0xffff0000),
          ],
          stops: [
            0,
            0.17,
            0.33,
            0.5,
            0.67,
            0.83,
            1,
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

