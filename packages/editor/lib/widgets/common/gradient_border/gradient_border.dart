import 'package:flutter/widgets.dart';
import 'gradient_border_app.dart'
    if (dart.library.html) 'gradient_border_web.dart';

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
  void paint(Canvas canvas, Size size) =>
      paintGradientBorder(canvas, _paint, size, strokeWidth, radius, gradient);

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => oldDelegate != this;
}
