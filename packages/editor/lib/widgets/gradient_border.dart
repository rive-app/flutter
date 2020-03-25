import 'package:flutter/widgets.dart';

/// Paints a gradient border around a widget
/// Make sure the child widget is transparent around the area
/// where the border will be painted.
class GradientBorder extends StatelessWidget {
  final _GradientPainter _painter;
  final bool _shouldPaint;
  final Widget _child;

  GradientBorder({
    @required double strokeWidth,
    @required double radius,
    @required Gradient gradient,
    @required Widget child,
    bool shouldPaint = false,
  })  : _painter = _GradientPainter(
            strokeWidth: strokeWidth, radius: radius, gradient: gradient),
        _shouldPaint = shouldPaint,
        _child = child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _shouldPaint ? _painter : null,
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
    canvas.drawPath(
        Path.combine(
          PathOperation.difference,
          Path()..addRRect(outerRRect),
          Path()..addRRect(innerRRect),
        ),
        _paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => oldDelegate != this;
}
