import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:rive/rive_core/shapes/shape_paint_container.dart';

class ShapePaintMutator {
  ShapePaintContainer _shapePaintContainer;
  Paint _paint;
  ShapePaintContainer get shapePaintContainer => _shapePaintContainer;
  Paint get paint => _paint;
  @mustCallSuper
  void initializePaintMutator(ShapePaintContainer container, Paint paint) {
    _shapePaintContainer = container;
    _paint = paint;
    _shapePaintContainer?.onPaintMutatorChanged(this);
  }
}
