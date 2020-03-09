/// Core automatically generated
/// lib/src/generated/shapes/straight_vertex_base.dart.
/// Do not modify manually.

import 'package:flutter/material.dart';
import 'package:rive_core/shapes/path_vertex.dart';
import 'package:rive_core/src/generated/component_base.dart';
import 'package:rive_core/src/generated/shapes/path_vertex_base.dart';

abstract class StraightVertexBase extends PathVertex {
  static const int typeKey = 5;
  @override
  int get coreType => StraightVertexBase.typeKey;
  @override
  Set<int> get coreTypes => {
        StraightVertexBase.typeKey,
        PathVertexBase.typeKey,
        ComponentBase.typeKey
      };

  /// --------------------------------------------------------------------------
  /// Radius field with key 26.
  double _radius;
  static const int radiusPropertyKey = 26;

  /// Radius of the vertex
  double get radius => _radius;

  /// Change the [_radius] field value.
  /// [radiusChanged] will be invoked only if the field's value has changed.
  set radius(double value) {
    if (_radius == value) {
      return;
    }
    double from = _radius;
    _radius = value;
    radiusChanged(from, value);
  }

  @mustCallSuper
  void radiusChanged(double from, double to) {
    onPropertyChanged(radiusPropertyKey, from, to);
  }

  @override
  void changeNonNull() {
    super.changeNonNull();
    if (radius != null) {
      onPropertyChanged(radiusPropertyKey, radius, radius);
    }
  }

  @override
  K getProperty<K>(int propertyKey) {
    switch (propertyKey) {
      case radiusPropertyKey:
        return radius as K;
      default:
        return super.getProperty<K>(propertyKey);
    }
  }
}
