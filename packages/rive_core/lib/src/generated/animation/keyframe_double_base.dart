/// Core automatically generated
/// lib/src/generated/animation/keyframe_double_base.dart.
/// Do not modify manually.

import 'package:meta/meta.dart';
import 'package:rive_core/animation/keyframe.dart';
import 'package:rive_core/src/generated/animation/keyframe_base.dart';

abstract class KeyFrameDoubleBase extends KeyFrame {
  static const int typeKey = 30;
  @override
  int get coreType => KeyFrameDoubleBase.typeKey;
  @override
  Set<int> get coreTypes => {KeyFrameDoubleBase.typeKey, KeyFrameBase.typeKey};

  /// --------------------------------------------------------------------------
  /// Value field with key 70.
  double _value;
  static const int valuePropertyKey = 70;
  double get value => _value;

  /// Change the [_value] field value.
  /// [valueChanged] will be invoked only if the field's value has changed.
  set value(double value) {
    if (_value == value) {
      return;
    }
    double from = _value;
    _value = value;
    valueChanged(from, value);
  }

  @mustCallSuper
  void valueChanged(double from, double to) {
    onPropertyChanged(valuePropertyKey, from, to);
  }

  @override
  void changeNonNull() {
    super.changeNonNull();
    if (value != null) {
      onPropertyChanged(valuePropertyKey, value, value);
    }
  }

  @override
  K getProperty<K>(int propertyKey) {
    switch (propertyKey) {
      case valuePropertyKey:
        return value as K;
      default:
        return super.getProperty<K>(propertyKey);
    }
  }
}
