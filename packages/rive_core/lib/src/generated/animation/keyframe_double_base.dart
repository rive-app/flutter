/// Core automatically generated
/// lib/src/generated/animation/keyframe_double_base.dart.
/// Do not modify manually.

import 'package:core/core.dart';
import 'package:rive_core/animation/keyframe.dart';
import 'package:rive_core/src/generated/animation/keyframe_base.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';
import 'dart:collection';

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
    onPropertyChanged(valuePropertyKey, from, value);
    valueChanged(from, value);
  }

  void valueChanged(double from, double to);

  @override
  void changeNonNull() {
    super.changeNonNull();
    if (value != null) {
      onPropertyChanged(valuePropertyKey, value, value);
    }
  }

  @override
  void writeRuntimeProperties(BinaryWriter writer, HashMap<Id, int> idLookup) {
    super.writeRuntimeProperties(writer, idLookup);
    if (_value != null) {
      context.doubleType.write(writer, _value);
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

  @override
  bool hasProperty(int propertyKey) {
    switch (propertyKey) {
      case valuePropertyKey:
        return true;
      default:
        return super.hasProperty(propertyKey);
    }
  }
}
