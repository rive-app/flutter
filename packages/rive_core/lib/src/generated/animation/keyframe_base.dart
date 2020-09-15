/// Core automatically generated lib/src/generated/animation/keyframe_base.dart.
/// Do not modify manually.

import 'dart:collection';
import 'package:core/core.dart';
import 'package:core/field_types/core_field_type.dart';
import 'package:rive_core/src/generated/rive_core_context.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

abstract class KeyFrameBase<T extends RiveCoreContext> extends Core<T> {
  static const int typeKey = 29;
  @override
  int get coreType => KeyFrameBase.typeKey;
  @override
  Set<int> get coreTypes => {KeyFrameBase.typeKey};

  /// --------------------------------------------------------------------------
  /// KeyedPropertyId field with key 72.
  Id _keyedPropertyId;
  static const int keyedPropertyIdPropertyKey = 72;

  /// The id of the KeyedProperty this KeyFrame belongs to.
  Id get keyedPropertyId => _keyedPropertyId;

  /// Change the [_keyedPropertyId] field value.
  /// [keyedPropertyIdChanged] will be invoked only if the field's value has
  /// changed.
  set keyedPropertyId(Id value) {
    if (_keyedPropertyId == value) {
      return;
    }
    Id from = _keyedPropertyId;
    _keyedPropertyId = value;
    onPropertyChanged(keyedPropertyIdPropertyKey, from, value);
    keyedPropertyIdChanged(from, value);
  }

  void keyedPropertyIdChanged(Id from, Id to);

  /// --------------------------------------------------------------------------
  /// Frame field with key 67.
  int _frame;
  static const int framePropertyKey = 67;

  /// Timecode as frame number can be converted to time by dividing by animation
  /// fps.
  int get frame => _frame;

  /// Change the [_frame] field value.
  /// [frameChanged] will be invoked only if the field's value has changed.
  set frame(int value) {
    if (_frame == value) {
      return;
    }
    int from = _frame;
    _frame = value;
    onPropertyChanged(framePropertyKey, from, value);
    frameChanged(from, value);
  }

  void frameChanged(int from, int to);

  /// --------------------------------------------------------------------------
  /// InterpolationType field with key 68.
  int _interpolationType;
  static const int interpolationTypePropertyKey = 68;

  /// The type of interpolation index in KeyframeInterpolation applied to this
  /// keyframe.
  int get interpolationType => _interpolationType;

  /// Change the [_interpolationType] field value.
  /// [interpolationTypeChanged] will be invoked only if the field's value has
  /// changed.
  set interpolationType(int value) {
    if (_interpolationType == value) {
      return;
    }
    int from = _interpolationType;
    _interpolationType = value;
    onPropertyChanged(interpolationTypePropertyKey, from, value);
    interpolationTypeChanged(from, value);
  }

  void interpolationTypeChanged(int from, int to);

  /// --------------------------------------------------------------------------
  /// InterpolatorId field with key 69.
  Id _interpolatorId;
  static const int interpolatorIdPropertyKey = 69;

  /// The id of the custom interpolator used when interpolation is Cubic.
  Id get interpolatorId => _interpolatorId;

  /// Change the [_interpolatorId] field value.
  /// [interpolatorIdChanged] will be invoked only if the field's value has
  /// changed.
  set interpolatorId(Id value) {
    if (_interpolatorId == value) {
      return;
    }
    Id from = _interpolatorId;
    _interpolatorId = value;
    onPropertyChanged(interpolatorIdPropertyKey, from, value);
    interpolatorIdChanged(from, value);
  }

  void interpolatorIdChanged(Id from, Id to);

  @override
  void changeNonNull() {
    if (_keyedPropertyId != null) {
      onPropertyChanged(
          keyedPropertyIdPropertyKey, _keyedPropertyId, _keyedPropertyId);
    }
    if (_frame != null) {
      onPropertyChanged(framePropertyKey, _frame, _frame);
    }
    if (_interpolationType != null) {
      onPropertyChanged(
          interpolationTypePropertyKey, _interpolationType, _interpolationType);
    }
    if (_interpolatorId != null) {
      onPropertyChanged(
          interpolatorIdPropertyKey, _interpolatorId, _interpolatorId);
    }
  }

  @override
  void writeRuntimeProperties(BinaryWriter writer,
      HashMap<int, CoreFieldType> propertyToField, HashMap<Id, int> idLookup) {
    if (_frame != null && exports(framePropertyKey)) {
      context.uintType.writeRuntimeProperty(
          framePropertyKey, writer, _frame, propertyToField);
    }
    if (_interpolationType != null && exports(interpolationTypePropertyKey)) {
      context.uintType.writeRuntimeProperty(interpolationTypePropertyKey,
          writer, _interpolationType, propertyToField);
    }
    if (_interpolatorId != null && exports(interpolatorIdPropertyKey)) {
      var value = idLookup[_interpolatorId];
      if (value != null) {
        context.uintType.writeRuntimeProperty(
            interpolatorIdPropertyKey, writer, value, propertyToField);
      }
    }
  }

  @override
  K getProperty<K>(int propertyKey) {
    switch (propertyKey) {
      case keyedPropertyIdPropertyKey:
        return keyedPropertyId as K;
      case framePropertyKey:
        return frame as K;
      case interpolationTypePropertyKey:
        return interpolationType as K;
      case interpolatorIdPropertyKey:
        return interpolatorId as K;
      default:
        return super.getProperty<K>(propertyKey);
    }
  }

  @override
  bool hasProperty(int propertyKey) {
    switch (propertyKey) {
      case keyedPropertyIdPropertyKey:
      case framePropertyKey:
      case interpolationTypePropertyKey:
      case interpolatorIdPropertyKey:
        return true;
      default:
        return super.hasProperty(propertyKey);
    }
  }
}
