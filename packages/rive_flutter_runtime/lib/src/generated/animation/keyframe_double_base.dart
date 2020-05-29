/// Core automatically generated
/// lib/src/generated/animation/keyframe_double_base.dart.
/// Do not modify manually.

import 'package:rive/rive_core/animation/keyframe.dart';
import 'package:rive/src/core/core.dart';
import 'package:rive/src/generated/animation/keyframe_base.dart';

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

  void valueChanged(double from, double to);
}
