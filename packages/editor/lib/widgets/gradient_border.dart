import 'package:flutter/widgets.dart';

const _transparent =
    LinearGradient(colors: [Color(0x00000000), Color(0x00000000)]);

/// Paints a gradient border around a widget
/// Make sure the child widget is transparent around the area
/// where the border will be painted.
class GradientBorder extends StatelessWidget {
  final _GradientPainter _painter;
  final bool shouldPaint;
  final Widget _child;

  GradientBorder({
    @required double strokeWidth,
    @required double radius,
    @required Gradient gradient,
    @required Widget child,
    this.shouldPaint = false,
  })  : _painter = _GradientPainter(
            strokeWidth: strokeWidth,
            radius: radius,
            gradient: shouldPaint ? gradient : _transparent),
        _child = child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _painter,
      child: _child,
    );
  }
}

/// Custom painter for painting curved gradient borders
class _GradientPainter extends CustomPainter {
  _GradientPainter(
      {@required this.strokeWidth,
      @required this.radius,
      @required this.gradient})
      : _paint = Paint();

  final Paint _paint;
  final double radius;
  final double strokeWidth;
  final Gradient gradient;

  @override
  void paint(Canvas canvas, Size size) {
    // create outer rectangle equals size
    final outerRect = Offset.zero & size;
    final outerRRect =
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));

    // create inner rectangle smaller by strokeWidth
    final innerRect = Rect.fromLTWH(strokeWidth, strokeWidth,
        size.width - strokeWidth * 2, size.height - strokeWidth * 2);
    final innerRRect = RRect.fromRectAndRadius(
        innerRect, Radius.circular(radius - strokeWidth));

    // apply gradient shader
    _paint.shader = gradient.createShader(outerRect);

    // create difference between outer and inner paths and draw it
    try {
      canvas.drawPath(
          Path.combine(
            PathOperation.difference,
            Path()..addRRect(outerRRect),
            Path()..addRRect(innerRRect),
          ),
          _paint);
    } on UnimplementedError catch (e) {
      // Path.combine is not implemented on the web
      Paint paint = Paint()
        ..color = gradient.colors.first
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      Path path = Path()..addRRect(outerRRect);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => oldDelegate != this;
}
