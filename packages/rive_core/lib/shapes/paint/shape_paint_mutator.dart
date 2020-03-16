import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:rive_core/shapes/shape.dart';

class ShapePaintMutator {
  Shape _shape;
  Paint _paint;

  Shape get shape => _shape;
  Paint get paint => _paint;

  @mustCallSuper
  void initializePaintMutator(Shape shape, Paint paint) {
    _shape = shape;
    _paint = paint;
  }
}
