import 'package:flutter/material.dart';

/// Draws a color swatch (paletted of colors blended as a gradient).
class ColorPreview extends LeafRenderObjectWidget {
  /// The colors in this swatch.
  final List<Color> colors;

  const ColorPreview({
    @required this.colors,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _ColorPreviewRenderObject()..colors = colors;
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant _ColorPreviewRenderObject renderObject) {
    renderObject.colors = colors;
  }

  @override
  void didUnmountRenderObject(
      covariant _ColorPreviewRenderObject renderObject) {
    // Any cleanup to do here?
  }
}

class _ColorPreviewRenderObject extends RenderBox {
  List<Color> _colors;

  static final Paint _borderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..color = Colors.white
    ..strokeWidth = 1;

  static final Paint _fillPaint = Paint()..style = PaintingStyle.fill;

  List<Color> get colors => _colors;
  set colors(List<Color> value) {
    if (_colors == value) {
      return;
    }
    _colors = value;
    markNeedsPaint();
  }

  @override
  void performLayout() {
    size = const Size(30, 20);
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    var canvas = context.canvas;
    if (colors.length > 1) {
      _fillPaint
        ..shader = LinearGradient(
          colors: colors,
        ).createShader(offset & size)
        ..color = const Color(0xFFFFFFFF);
    } else if (colors.length == 1) {
      _fillPaint
        ..shader = null
        ..color = colors.first;
    }

    if (colors.isNotEmpty) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(offset & size, const Radius.circular(2)),
          _fillPaint);
    }

    canvas.drawRRect(
        RRect.fromRectAndRadius(offset & size, const Radius.circular(2)),
        _borderPaint);
  }
}
