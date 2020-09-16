import 'package:flutter/material.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_editor/rive/image_cache.dart';

/// Draws a color swatch (paletted of colors blended as a gradient).
class ColorPreview extends LeafRenderObjectWidget {
  /// The colors in this swatch.
  final List<Color> colors;
  final RiveImageCache imageCache;

  const ColorPreview({
    @required this.colors,
    @required this.imageCache,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _ColorPreviewRenderObject()
      ..colors = colors
      ..imageCache = imageCache;
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant _ColorPreviewRenderObject renderObject) {
    renderObject
      ..colors = colors
      ..imageCache = imageCache;
  }

  @override
  void didUnmountRenderObject(
      covariant _ColorPreviewRenderObject renderObject) {
    // Any cleanup to do here?
  }
}

class _ColorPreviewRenderObject extends RenderBox {
  List<Color> _colors;
  DpiImage _gridImage;

  static final Paint _borderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..color = Colors.white
    ..strokeWidth = 1;

  static final Paint _fillPaint = Paint()..style = PaintingStyle.fill;

  RiveImageCache get imageCache => _gridImage?.cache;
  set imageCache(RiveImageCache value) {
    if (_gridImage?.cache == value) {
      return;
    }
    _gridImage = DpiImage(
        cache: value,
        loaded: () {
          if (attached) {
            markNeedsPaint();
          }
        },
        filenameFor: (dpi) {
          var size = dpi == 1 ? 1 : 2;
          return 'assets/images/artboard_bg_${size}x.png';
        });
  }

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
    var image = _gridImage?.image;
    if (image != null) {
      var identity = Mat2D.fromScaling(Vec2D.fromValues(0.7, 0.7));
      var gridPaint = Paint()
        ..shader = ImageShader(
            image, TileMode.repeated, TileMode.repeated, identity.mat4);
      canvas.drawRRect(
          RRect.fromRectAndRadius(offset & size, const Radius.circular(2)),
          gridPaint);
    }
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
