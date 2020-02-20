/// Core automatically generated lib/src/generated/shapes/rectangle_base.dart.
/// Do not modify manually.

import 'package:flutter/material.dart';
import '../../../shapes/parametric_path.dart';

abstract class RectangleBase extends ParametricPath {
  static const int typeKey = 7;
  @override
  int get coreType => RectangleBase.typeKey;

  /// --------------------------------------------------------------------------
  /// CornerRadius field with key 31.
  double _cornerRadius;
  static const int cornerRadiusPropertyKey = 31;

  /// Radius of the corners of this rectangle
  double get cornerRadius => _cornerRadius;

  /// Change the [_cornerRadius] field value.
  /// [cornerRadiusChanged] will be invoked only if the field's value has
  /// changed.
  set cornerRadius(double value) {
    if (_cornerRadius == value) {
      return;
    }
    double from = _cornerRadius;
    _cornerRadius = value;
    cornerRadiusChanged(from, value);
  }

  @mustCallSuper
  void cornerRadiusChanged(double from, double to) {
    onPropertyChanged(cornerRadiusPropertyKey, from, to);
  }

  @override
  void changeNonNull() {
    super.changeNonNull();
    if (cornerRadius != null) {
      onPropertyChanged(cornerRadiusPropertyKey, cornerRadius, cornerRadius);
    }
  }

  @override
  K getProperty<K>(int propertyKey) {
    switch (propertyKey) {
      case cornerRadiusPropertyKey:
        return cornerRadius as K;
      default:
        return super.getProperty<K>(propertyKey);
    }
  }
}
