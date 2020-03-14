/// Core automatically generated
/// lib/src/generated/shapes/paint/radial_gradient_base.dart.
/// Do not modify manually.

import 'package:meta/meta.dart';
import 'package:rive_core/shapes/paint/linear_gradient.dart';
import 'package:rive_core/src/generated/component_base.dart';
import 'package:rive_core/src/generated/container_component_base.dart';
import 'package:rive_core/src/generated/shapes/paint/linear_gradient_base.dart';

abstract class RadialGradientBase extends LinearGradient {
  static const int typeKey = 17;
  @override
  int get coreType => RadialGradientBase.typeKey;
  @override
  Set<int> get coreTypes => {
        RadialGradientBase.typeKey,
        LinearGradientBase.typeKey,
        ContainerComponentBase.typeKey,
        ComponentBase.typeKey
      };

  /// --------------------------------------------------------------------------
  /// Radius field with key 36.
  double _radius = 0;
  static const int radiusPropertyKey = 36;
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
