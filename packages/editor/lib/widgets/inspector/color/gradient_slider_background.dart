import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/inspector/color/inspecting_color.dart';
import 'package:rive_editor/widgets/inspector/color/opacity_slider_background.dart';

/// Background for the Gradient Stop slider.
class GradientSliderBackground extends CustomPainter {
  final List<Color> colors;
  final List<double> positions;
  final Color background;

  GradientSliderBackground(List<InspectingColorStop> stops, this.background)
      : colors = List<Color>(stops.length),
        positions = List<double>(stops.length) {
    for (int i = 0; i < stops.length; i++) {
      final stop = stops[i];
      colors[i] = stop.color;
      positions[i] = stop.position;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;

    OpacitySliderBackground.paintCheckerPattern(canvas, size, background,
        foreground: () {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            colors: colors,
            stops: positions,
          ).createShader(rect),
      );
    });
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
