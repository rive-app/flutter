import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:rive_core/shapes/shape_paint_container.dart';

class ShapePaintMutator {
  ShapePaintContainer _shapePaintContainer;
  Paint _paint;

  /// The container is usually either a Shape or an Artboard, basically any of
  /// the various ContainerComponents that can contain Fills or Strokes.
  ShapePaintContainer get shapePaintContainer => _shapePaintContainer;
  Paint get paint => _paint;

  @mustCallSuper
  void initializePaintMutator(ShapePaintContainer container, Paint paint) {
    _shapePaintContainer = container;
    _paint = paint;
  }
}
