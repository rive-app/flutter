import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A drop shadow that works with layer so it is computed accurately for
/// complicated content. Fairly expensive.
class DropShadow extends SingleChildRenderObjectWidget {
  final Color color;

  final double blur;
  final Offset offset;
  const DropShadow({
    Key key,
    this.color,
    this.blur,
    this.offset,
    Widget child,
  }) : super(key: key, child: child);

  @override
  RenderDropShadow createRenderObject(BuildContext context) {
    return RenderDropShadow()
      ..color = color
      ..blur = blur
      ..offset = offset;
  }

  @override
  void updateRenderObject(BuildContext context, RenderDropShadow renderObject) {
    renderObject
      ..color = color
      ..blur = blur
      ..offset = offset;
  }
}

class RenderDropShadow extends RenderProxyBox {
  Color _color;

  double _blur;

  Offset _offset;
  RenderDropShadow({
    RenderBox child,
  }) : super(child);
  @override
  bool get alwaysNeedsCompositing => child != null;

  double get blur => _blur;
  set blur(double value) {
    if (_blur == value) return;
    _blur = value;
    markNeedsPaint();
  }

  Color get color => _color;
  set color(Color value) {
    if (_color == value) return;
    _color = value;
    markNeedsPaint();
  }

  Offset get offset => _offset;
  set offset(Offset value) {
    if (_offset == value) return;
    _offset = value;
    markNeedsPaint();
  }

  ui.ImageFilter _blurFilter(double x, double y) {
    double bx = x.abs() < 0.1 ? 0 : x;
    double by = y.abs() < 0.1 ? 0 : y;
    return bx == 0 && by == 0
        ? null
        : ui.ImageFilter.blur(sigmaX: bx, sigmaY: by);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      var canvas = context.canvas;

      var shadowPaint = Paint()
        ..color = const Color(0xFFFFFFFF)
        ..imageFilter = _blurFilter(blur, blur)
        ..colorFilter = ui.ColorFilter.mode(color, ui.BlendMode.srcIn);

      canvas.saveLayer(null, shadowPaint);
      context.paintChild(child, offset + _offset);
      canvas.restore();
      context.paintChild(child, offset);
    }
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (child != null) visitor(child);
  }
}
