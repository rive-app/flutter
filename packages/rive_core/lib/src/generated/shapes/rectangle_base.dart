/// Core automatically generated lib/src/generated/shapes/rectangle_base.dart.
/// Do not modify manually.

import 'package:meta/meta.dart';
import 'package:rive_core/shapes/parametric_path.dart';
import 'package:rive_core/src/generated/component_base.dart';
import 'package:rive_core/src/generated/container_component_base.dart';
import 'package:rive_core/src/generated/node_base.dart';
import 'package:rive_core/src/generated/shapes/parametric_path_base.dart';
import 'package:rive_core/src/generated/shapes/path_base.dart';

abstract class RectangleBase extends ParametricPath {
  static const int typeKey = 7;
  @override
  int get coreType => RectangleBase.typeKey;
  @override
  Set<int> get coreTypes => {
        RectangleBase.typeKey,
        ParametricPathBase.typeKey,
        PathBase.typeKey,
        NodeBase.typeKey,
        ContainerComponentBase.typeKey,
        ComponentBase.typeKey
      };

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
