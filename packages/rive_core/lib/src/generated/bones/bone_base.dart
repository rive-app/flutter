/// Core automatically generated lib/src/generated/bones/bone_base.dart.
/// Do not modify manually.

import 'dart:collection';
import 'package:core/core.dart';
import 'package:core/key_state.dart';
import 'package:rive_core/bones/skeletal_component.dart';
import 'package:rive_core/src/generated/bones/skeletal_component_base.dart';
import 'package:rive_core/src/generated/component_base.dart';
import 'package:rive_core/src/generated/container_component_base.dart';
import 'package:rive_core/src/generated/transform_component_base.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

abstract class BoneBase extends SkeletalComponent {
  static const int typeKey = 40;
  @override
  int get coreType => BoneBase.typeKey;
  @override
  Set<int> get coreTypes => {
        BoneBase.typeKey,
        SkeletalComponentBase.typeKey,
        TransformComponentBase.typeKey,
        ContainerComponentBase.typeKey,
        ComponentBase.typeKey
      };

  /// --------------------------------------------------------------------------
  /// Length field with key 89.
  double _length = 0;
  double _lengthAnimated;
  KeyState _lengthKeyState = KeyState.none;
  static const int lengthPropertyKey = 89;

  /// Get the [_length] field value.Note this may not match the core value if
  /// animation mode is active.
  double get length => _lengthAnimated ?? _length;

  /// Get the non-animation [_length] field value.
  double get lengthCore => _length;

  /// Change the [_length] field value.
  /// [lengthChanged] will be invoked only if the field's value has changed.
  set lengthCore(double value) {
    if (_length == value) {
      return;
    }
    double from = _length;
    _length = value;
    onPropertyChanged(lengthPropertyKey, from, value);
    lengthChanged(from, value);
  }

  set length(double value) {
    if (length == value) {
      return;
    }
    if (context != null && context.isAnimating) {
      _lengthAnimate(value, true);
      return;
    }
    lengthCore = value;
  }

  void _lengthAnimate(double value, bool autoKey) {
    if (_lengthAnimated == value) {
      return;
    }
    double from = length;
    _lengthAnimated = value;
    double to = length;
    onAnimatedPropertyChanged(lengthPropertyKey, autoKey, from, to);
    lengthChanged(from, to);
  }

  double get lengthAnimated => _lengthAnimated;
  set lengthAnimated(double value) => _lengthAnimate(value, false);
  KeyState get lengthKeyState => _lengthKeyState;
  set lengthKeyState(KeyState value) {
    if (_lengthKeyState == value) {
      return;
    }
    _lengthKeyState = value;
    // Force update anything listening on this property.
    onAnimatedPropertyChanged(
        lengthPropertyKey, false, _lengthAnimated, _lengthAnimated);
  }

  void lengthChanged(double from, double to);

  @override
  void changeNonNull() {
    super.changeNonNull();
    if (_length != null) {
      onPropertyChanged(lengthPropertyKey, _length, _length);
    }
  }

  @override
  void writeRuntimeProperties(BinaryWriter writer, HashMap<Id, int> idLookup) {
    super.writeRuntimeProperties(writer, idLookup);
    if (_length != null && exports(lengthPropertyKey)) {
      context.doubleType
          .writeRuntimeProperty(lengthPropertyKey, writer, _length);
    }
  }

  @override
  bool exports(int propertyKey) {
    switch (propertyKey) {
      case lengthPropertyKey:
        return _length != 0;
    }
    return super.exports(propertyKey);
  }

  @override
  K getProperty<K>(int propertyKey) {
    switch (propertyKey) {
      case lengthPropertyKey:
        return length as K;
      default:
        return super.getProperty<K>(propertyKey);
    }
  }

  @override
  bool hasProperty(int propertyKey) {
    switch (propertyKey) {
      case lengthPropertyKey:
        return true;
      default:
        return super.hasProperty(propertyKey);
    }
  }
}
