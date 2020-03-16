import 'package:flutter/material.dart';

/// A visual indicator of the current value in a slider/picker for a color
/// value.
/// ![](https://assets.rvcd.in/inspector/color/color_grabber.png)
class ColorGrabber extends StatelessWidget {
  final Color color;
  final Size size;

  const ColorGrabber({
    Key key,
    this.color,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width,
      height: size.height,
      child: CustomPaint(
        painter: _ColorGrabberPainter(
          color: color,
        ),
      ),
    );
  }
}


/// Custom painter for the [ColorGrabber].
class _ColorGrabberPainter extends CustomPainter {
  final Color color;
  const _ColorGrabberPainter({this.color});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawOval(
      const Offset(0, 2) & size,
      Paint()
        ..color = Colors.black.withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal,
          5,
        ),
    );
    canvas.drawOval(
      Offset.zero & size,
      Paint()..color = color,
    );
    canvas.drawOval(
      Offset.zero & size,
      Paint()
        ..strokeWidth = 1
        ..color = Colors.white
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_ColorGrabberPainter oldDelegate) =>
      oldDelegate.color != color;
}