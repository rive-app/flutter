/// Core automatically generated
/// lib/src/generated/animation/cubic_interpolator_base.dart.
/// Do not modify manually.

import 'package:core/core.dart';
import 'package:meta/meta.dart';
import 'package:rive_core/src/generated/rive_core_context.dart';

abstract class CubicInterpolatorBase<T extends RiveCoreContext>
    extends Core<T> {
  static const int typeKey = 28;
  @override
  int get coreType => CubicInterpolatorBase.typeKey;
  @override
  Set<int> get coreTypes => {CubicInterpolatorBase.typeKey};

  /// --------------------------------------------------------------------------
  /// X1 field with key 63.
  double _x1;
  static const int x1PropertyKey = 63;
  double get x1 => _x1;

  /// Change the [_x1] field value.
  /// [x1Changed] will be invoked only if the field's value has changed.
  set x1(double value) {
    if (_x1 == value) {
      return;
    }
    double from = _x1;
    _x1 = value;
    x1Changed(from, value);
  }

  @mustCallSuper
  void x1Changed(double from, double to) {
    onPropertyChanged(x1PropertyKey, from, to);
  }

  /// --------------------------------------------------------------------------
  /// Y1 field with key 64.
  double _y1;
  static const int y1PropertyKey = 64;
  double get y1 => _y1;

  /// Change the [_y1] field value.
  /// [y1Changed] will be invoked only if the field's value has changed.
  set y1(double value) {
    if (_y1 == value) {
      return;
    }
    double from = _y1;
    _y1 = value;
    y1Changed(from, value);
  }

  @mustCallSuper
  void y1Changed(double from, double to) {
    onPropertyChanged(y1PropertyKey, from, to);
  }

  /// --------------------------------------------------------------------------
  /// X2 field with key 65.
  double _x2;
  static const int x2PropertyKey = 65;
  double get x2 => _x2;

  /// Change the [_x2] field value.
  /// [x2Changed] will be invoked only if the field's value has changed.
  set x2(double value) {
    if (_x2 == value) {
      return;
    }
    double from = _x2;
    _x2 = value;
    x2Changed(from, value);
  }

  @mustCallSuper
  void x2Changed(double from, double to) {
    onPropertyChanged(x2PropertyKey, from, to);
  }

  /// --------------------------------------------------------------------------
  /// Y2 field with key 66.
  double _y2;
  static const int y2PropertyKey = 66;
  double get y2 => _y2;

  /// Change the [_y2] field value.
  /// [y2Changed] will be invoked only if the field's value has changed.
  set y2(double value) {
    if (_y2 == value) {
      return;
    }
    double from = _y2;
    _y2 = value;
    y2Changed(from, value);
  }

  @mustCallSuper
  void y2Changed(double from, double to) {
    onPropertyChanged(y2PropertyKey, from, to);
  }

  @override
  void changeNonNull() {
    if (x1 != null) {
      onPropertyChanged(x1PropertyKey, x1, x1);
    }
    if (y1 != null) {
      onPropertyChanged(y1PropertyKey, y1, y1);
    }
    if (x2 != null) {
      onPropertyChanged(x2PropertyKey, x2, x2);
    }
    if (y2 != null) {
      onPropertyChanged(y2PropertyKey, y2, y2);
    }
  }

  @override
  K getProperty<K>(int propertyKey) {
    switch (propertyKey) {
      case x1PropertyKey:
        return x1 as K;
      case y1PropertyKey:
        return y1 as K;
      case x2PropertyKey:
        return x2 as K;
      case y2PropertyKey:
        return y2 as K;
      default:
        return super.getProperty<K>(propertyKey);
    }
  }
}
