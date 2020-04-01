import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum TabDecorationStyle { separator, fill }

/// Background of a tab item with rounded corners on the top and rounded flaps
/// on the bottom.
class TabDecoration extends Decoration {
  static const double cornerRadius = 6;
  const TabDecoration(
      {this.color,
      this.invertLeft = false,
      this.invertRight = false,
      this.style = TabDecorationStyle.fill});

  final Color color;
  // Invert the curve at te bottom of the tab
  // Used to ensure that hovered tabs don't obscure selected tab curves
  final bool invertLeft;
  final bool invertRight;

  /// Whether this is filling or drawing a separator
  final TabDecorationStyle style;

  @override
  Path getClipPath(Rect rect, TextDirection textDirection) => null;

  @override
  bool get isComplex => false;

  @override
  TabDecoration lerpFrom(Decoration a, double t) {
    if (a is TabDecoration) {
      return TabDecoration(
          color: Color.lerp(a.color, color, t), style: a.style);
    } else {
      return TabDecoration(color: Color.lerp(null, color, t), style: style);
    }
  }

  @override
  TabDecoration lerpTo(Decoration b, double t) {
    if (b is TabDecoration) {
      return TabDecoration(
          color: Color.lerp(color, b.color, t), style: b.style);
    } else {
      return TabDecoration(color: Color.lerp(color, null, t), style: style);
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
    return _TabDecorationPainter(
      this,
      onChanged,
      invertLeft: invertLeft,
      invertRight: invertRight,
      style: style,
    );
  }
}

const double _arcConstant = 0.55;
const double _iarcConstant = 1.0 - _arcConstant;
const double _cornerRadius = TabDecoration.cornerRadius;

/// An object that paints a [_TabDecorationPainter] into a canvas.
class _TabDecorationPainter extends BoxPainter {
  _TabDecorationPainter(
    this._decoration,
    VoidCallback onChanged, {
    this.invertLeft = false,
    this.invertRight = false,
    this.style,
  })  : assert(_decoration != null),
        super(onChanged);

  final TabDecoration _decoration;
  final bool invertLeft;
  final bool invertRight;
  final TabDecorationStyle style;

  Paint _cachedBackgroundPaint;
  Rect _rectForCachedBackgroundPaint;
  Paint _getBackgroundPaint(Rect rect, TextDirection textDirection) {
    assert(rect != null);

    if (_cachedBackgroundPaint == null ||
        _rectForCachedBackgroundPaint != rect) {
      final Paint paint = Paint();
      if (_decoration.color != null) paint.color = _decoration.color;

      _cachedBackgroundPaint = paint;
      switch (style) {
        case TabDecorationStyle.fill:
          paint.isAntiAlias = true;
          break;
        case TabDecorationStyle.separator:
          paint.isAntiAlias = false;
          break;
      }
    }

    return _cachedBackgroundPaint;
  }

  void _paintBox(
      Canvas canvas, Rect rect, Paint paint, TextDirection textDirection) {
    switch (style) {
      case TabDecorationStyle.separator:
        canvas.drawLine(
          rect.topRight.translate(1, _cornerRadius + 1),
          rect.bottomRight.translate(1, -_cornerRadius - 1),
          paint,
        );
        break;
      case TabDecorationStyle.fill:
        Path path = Path();

        if (invertLeft) {
          path.moveTo(_cornerRadius, rect.height);
          path.cubicTo(
              _cornerRadius - _cornerRadius * _arcConstant,
              rect.height,
              0,
              rect.height - _cornerRadius * _iarcConstant,
              0,
              rect.height - _cornerRadius);
        } else {
          path.moveTo(-_cornerRadius, rect.height);
          path.cubicTo(
              -_cornerRadius + _cornerRadius * _arcConstant,
              rect.height,
              0,
              rect.height - _iarcConstant * _cornerRadius,
              0,
              rect.height - _cornerRadius);
        }

        path.lineTo(0, _cornerRadius);

        path.cubicTo(0, _cornerRadius * _iarcConstant,
            _cornerRadius * _iarcConstant, 0, _cornerRadius, 0);

        path.lineTo(rect.width - _cornerRadius, 0);

        path.cubicTo(rect.width - _cornerRadius * _iarcConstant, 0, rect.width,
            _cornerRadius * _iarcConstant, rect.width, _cornerRadius);

        path.lineTo(rect.width, rect.height - _cornerRadius);

        if (invertRight) {
          path.cubicTo(
              rect.width,
              rect.height - _cornerRadius * _iarcConstant,
              rect.width - _cornerRadius * _iarcConstant,
              rect.height,
              rect.width - _cornerRadius,
              rect.height);
        } else {
          path.cubicTo(
              rect.width,
              rect.height - _cornerRadius * _iarcConstant,
              rect.width + _cornerRadius * _iarcConstant,
              rect.height,
              rect.width + _cornerRadius,
              rect.height);
        }

        path.close();
        canvas.save();
        canvas.translate(rect.left, rect.top);
        canvas.drawPath(path, paint);
        canvas.restore();
        break;
    }
  }

  void _paintBackgroundColor(
      Canvas canvas, Rect rect, TextDirection textDirection) {
    if (_decoration.color != null) {
      _paintBox(
          canvas,
          Rect.fromLTRB(
            rect.left,
            rect.top,
            rect.right,
            rect.bottom,
          ),
          _getBackgroundPaint(rect, textDirection),
          textDirection);
    }
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
