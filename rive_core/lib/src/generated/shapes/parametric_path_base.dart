/// Core automatically generated
/// lib/src/generated/shapes/parametric_path_base.dart.
/// Do not modify manually.

import 'package:flutter/material.dart';
import '../../../shapes/path.dart';

abstract class ParametricPathBase extends Path {
  /// --------------------------------------------------------------------------
  /// Width field with key 20.
  double _width;
  static const int widthPropertyKey = 20;

  /// Width of the parametric path.
  double get width => _width;

  /// Change the [_width] field value.
  /// [widthChanged] will be invoked only if the field's value has changed.
  set width(double value) {
    if (_width == value) {
      return;
    }
    double from = _width;
    _width = value;
    widthChanged(from, value);
  }

  @mustCallSuper
  void widthChanged(double from, double to) {
    onPropertyChanged(widthPropertyKey, from, to);
  }

  /// --------------------------------------------------------------------------
  /// Height field with key 21.
  double _height;
  static const int heightPropertyKey = 21;

  /// Height of the parametric path.
  double get height => _height;

  /// Change the [_height] field value.
  /// [heightChanged] will be invoked only if the field's value has changed.
  set height(double value) {
    if (_height == value) {
      return;
    }
    double from = _height;
    _height = value;
    heightChanged(from, value);
  }

  @mustCallSuper
  void heightChanged(double from, double to) {
    onPropertyChanged(heightPropertyKey, from, to);
  }

  @override
  void changeNonNull() {
    super.changeNonNull();
    if (width != null) {
      onPropertyChanged(widthPropertyKey, width, width);
    }
    if (height != null) {
      onPropertyChanged(heightPropertyKey, height, height);
    }
  }

  @override
  K getProperty<K>(int propertyKey) {
    switch (propertyKey) {
      case widthPropertyKey:
        return width as K;
      case heightPropertyKey:
        return height as K;
      default:
        return super.getProperty<K>(propertyKey);
    }
  }
}
