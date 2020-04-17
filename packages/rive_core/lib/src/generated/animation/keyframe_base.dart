/// Core automatically generated lib/src/generated/animation/keyframe_base.dart.
/// Do not modify manually.

import 'package:core/core.dart';
import 'package:meta/meta.dart';
import 'package:rive_core/src/generated/rive_core_context.dart';

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
    keyedPropertyIdChanged(from, value);
  }

  @mustCallSuper
  void keyedPropertyIdChanged(Id from, Id to) {
    onPropertyChanged(keyedPropertyIdPropertyKey, from, to);
  }

  /// --------------------------------------------------------------------------
  /// Frame field with key 67.
  int _frame;
  static const int framePropertyKey = 67;

  /// Timecode as frame number.
  int get frame => _frame;

  /// Change the [_frame] field value.
  /// [frameChanged] will be invoked only if the field's value has changed.
  set frame(int value) {
    if (_frame == value) {
      return;
    }
    int from = _frame;
    _frame = value;
    frameChanged(from, value);
  }

  @mustCallSuper
  void frameChanged(int from, int to) {
    onPropertyChanged(framePropertyKey, from, to);
  }

  /// --------------------------------------------------------------------------
  /// Interpolation field with key 68.
  int _interpolation;
  static const int interpolationPropertyKey = 68;

  /// The type of interpolation index in KeyInterpolatorType applied to this
  /// keyframe.
  int get interpolation => _interpolation;

  /// Change the [_interpolation] field value.
  /// [interpolationChanged] will be invoked only if the field's value has
  /// changed.
  set interpolation(int value) {
    if (_interpolation == value) {
      return;
    }
    int from = _interpolation;
    _interpolation = value;
    interpolationChanged(from, value);
  }

  @mustCallSuper
  void interpolationChanged(int from, int to) {
    onPropertyChanged(interpolationPropertyKey, from, to);
  }

  /// --------------------------------------------------------------------------
  /// InterpolatorId field with key 69.
  Id _interpolatorId;
  static const int interpolatorIdPropertyKey = 69;

  /// The id of the custom interpolator used when interpolation ==
  /// KeyInterpolatorType.custom.
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
    interpolatorIdChanged(from, value);
  }

  @mustCallSuper
  void interpolatorIdChanged(Id from, Id to) {
    onPropertyChanged(interpolatorIdPropertyKey, from, to);
  }

  @override
  void changeNonNull() {
    if (keyedPropertyId != null) {
      onPropertyChanged(
          keyedPropertyIdPropertyKey, keyedPropertyId, keyedPropertyId);
    }
    if (frame != null) {
      onPropertyChanged(framePropertyKey, frame, frame);
    }
    if (interpolation != null) {
      onPropertyChanged(interpolationPropertyKey, interpolation, interpolation);
    }
    if (interpolatorId != null) {
      onPropertyChanged(
          interpolatorIdPropertyKey, interpolatorId, interpolatorId);
    }
  }

  @override
  K getProperty<K>(int propertyKey) {
    switch (propertyKey) {
      case keyedPropertyIdPropertyKey:
        return keyedPropertyId as K;
      case framePropertyKey:
        return frame as K;
      case interpolationPropertyKey:
        return interpolation as K;
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
      case interpolationPropertyKey:
      case interpolatorIdPropertyKey:
        return true;
      default:
        return super.getProperty(propertyKey);
    }
  }
}
