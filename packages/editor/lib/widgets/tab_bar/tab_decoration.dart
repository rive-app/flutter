import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Background of a tab item with rounded corners on the top and rounded flaps
/// on the bottom.
class TabDecoration extends Decoration {
  const TabDecoration({
    this.color,
    this.invertLeft = false,
    this.invertRight = false,
  });

  final Color color;
  // Invert te curve at te bottom of the tab
  // Used to ensure that hovered tabs don't obscure selected tab curves
  final bool invertLeft;
  final bool invertRight;

  @override
  Path getClipPath(Rect rect, TextDirection textDirection) => null;

  @override
  bool get isComplex => false;

  @override
  TabDecoration lerpFrom(Decoration a, double t) {
    if (a is TabDecoration) {
      return TabDecoration(color: Color.lerp(a.color, color, t));
    } else {
      return TabDecoration(color: Color.lerp(null, color, t));
    }
  }

  @override
  TabDecoration lerpTo(Decoration b, double t) {
    if (b is TabDecoration) {
      return TabDecoration(color: Color.lerp(color, b.color, t));
    } else {
      return TabDecoration(color: Color.lerp(color, null, t));
    }
  }

  @override
  bool operator ==(dynamic other) =>
      other is TabDecoration && color == other.color;

  @override
  int get hashCode => color.hashCode;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..defaultDiagnosticsTreeStyle = DiagnosticsTreeStyle.whitespace
      ..emptyBodyDescription = '<no decorations specified>';

    properties.add(ColorProperty('color', color, defaultValue: null));
  }

  @override
  bool hitTest(Size size, Offset position, {TextDirection textDirection}) =>
      true;

  @override
  _TabDecorationPainter createBoxPainter([VoidCallback onChanged]) {
    assert(onChanged != null);
    return _TabDecorationPainter(this, onChanged,
        invertLeft: invertLeft, invertRight: invertRight);
  }
}

const double _arcConstant = 0.55;
const double _iarcConstant = 1.0 - _arcConstant;

/// An object that paints a [_TabDecorationPainter] into a canvas.
class _TabDecorationPainter extends BoxPainter {
  _TabDecorationPainter(
    this._decoration,
    VoidCallback onChanged, {
    this.invertLeft = false,
    this.invertRight = false,
  })  : assert(_decoration != null),
        super(onChanged);

  final TabDecoration _decoration;
  final bool invertLeft;
  final bool invertRight;

  Paint _cachedBackgroundPaint;
  Rect _rectForCachedBackgroundPaint;
  Paint _getBackgroundPaint(Rect rect, TextDirection textDirection) {
    assert(rect != null);

    if (_cachedBackgroundPaint == null ||
        _rectForCachedBackgroundPaint != rect) {
      final Paint paint = Paint();
      if (_decoration.color != null) paint.color = _decoration.color;

      _cachedBackgroundPaint = paint;
    }

    return _cachedBackgroundPaint;
  }

  void _paintBox(
      Canvas canvas, Rect rect, Paint paint, TextDirection textDirection) {
    const double cornerRadius = 6;

    Path path = Path();

    if (invertLeft) {
      path.moveTo(cornerRadius, rect.height);
      path.cubicTo(
          cornerRadius + cornerRadius * _arcConstant,
          rect.height,
          0,
          rect.height - cornerRadius * _iarcConstant,
          0,
          rect.height - cornerRadius);
    } else {
      path.moveTo(-cornerRadius, rect.height);
      path.cubicTo(
          -cornerRadius + cornerRadius * _arcConstant,
          rect.height,
          0,
          rect.height - _iarcConstant * cornerRadius,
          0,
          rect.height - cornerRadius);
    }

    path.lineTo(0, cornerRadius);

    path.cubicTo(0, cornerRadius * _iarcConstant, cornerRadius * _iarcConstant,
        0, cornerRadius, 0);

    path.lineTo(rect.width - cornerRadius, 0);

    path.cubicTo(rect.width - cornerRadius * _iarcConstant, 0, rect.width,
        cornerRadius * _iarcConstant, rect.width, cornerRadius);

    path.lineTo(rect.width, rect.height - cornerRadius);

    if (invertRight) {
      path.cubicTo(
          rect.width,
          rect.height - cornerRadius * _iarcConstant,
          rect.width - cornerRadius * _iarcConstant,
          rect.height,
          rect.width - cornerRadius,
          rect.height);
    } else {
      path.cubicTo(
          rect.width,
          rect.height - cornerRadius * _iarcConstant,
          rect.width + cornerRadius * _iarcConstant,
          rect.height,
          rect.width + cornerRadius,
          rect.height);
    }

    path.close();
    canvas.save();
    canvas.translate(rect.left, rect.top);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  void _paintBackgroundColor(
      Canvas canvas, Rect rect, TextDirection textDirection) {
    if (_decoration.color != null)
      _paintBox(canvas, rect, _getBackgroundPaint(rect, textDirection),
          textDirection);
  }

  /// Paint the box decoration into the given location on the given canvas
  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    assert(configuration != null);
    assert(configuration.size != null);
    final Rect rect = offset & configuration.size;
    final TextDirection textDirection = configuration.textDirection;
    _paintBackgroundColor(canvas, rect, textDirection);
  }

  @override
  String toString() {
    return 'BoxPainter for $_decoration';
  }
}
