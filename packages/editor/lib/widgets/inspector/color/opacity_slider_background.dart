import 'package:flutter/material.dart';

/// Background for the opacity slider.
class OpacitySliderBackground extends CustomPainter {
  final Color color;
  final Color background;
  const OpacitySliderBackground({this.color, this.background});

  @override
  void paint(Canvas canvas, Size size) {
    paintCheckerPattern(canvas, size, background, foreground: () {
      var rect = Offset.zero & size;
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            colors: [
              color.withOpacity(0),
              color,
            ],
            stops: const [
              0,
              1,
            ],
          ).createShader(rect),
      );
    });
  }

  @override
  bool shouldRepaint(OpacitySliderBackground oldDelegate) =>
      oldDelegate.color != color || oldDelegate.background != background;

  // Paint a clipped checker pattern.
  static void paintCheckerPattern(Canvas canvas, Size size, Color color,
      {void Function() foreground}) {
    final Rect rect = Offset.zero & size;

    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(
        rect,
        const Radius.circular(8),
      ),
    );

    const double gridSize = 6;
    double offset = size.height / 2 - gridSize;
    Rect gridRectA = Rect.fromLTWH(0, offset, gridSize, gridSize);
    Rect gridRectB =
        Rect.fromLTWH(gridSize, offset + gridSize, gridSize, gridSize);
    int count = (size.width / gridSize / 2).ceil();
    var gridPaint = Paint()..color = color;
    canvas.save();
    for (int i = 0; i < count; i++) {
      canvas.drawRect(gridRectA, gridPaint);
      canvas.drawRect(gridRectB, gridPaint);
      canvas.translate(gridSize * 2, 0);
    }
    canvas.restore();

    foreground?.call();
    canvas.restore();
  }
}
