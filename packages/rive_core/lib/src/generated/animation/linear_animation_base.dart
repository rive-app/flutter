/// Core automatically generated
/// lib/src/generated/animation/linear_animation_base.dart.
/// Do not modify manually.

import 'dart:collection';
import 'package:core/core.dart';
import 'package:rive_core/animation/animation.dart';
import 'package:rive_core/src/generated/animation/animation_base.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

abstract class LinearAnimationBase extends Animation {
  static const int typeKey = 31;
  @override
  int get coreType => LinearAnimationBase.typeKey;
  @override
  Set<int> get coreTypes =>
      {LinearAnimationBase.typeKey, AnimationBase.typeKey};

  /// --------------------------------------------------------------------------
  /// Fps field with key 56.
  int _fps = 60;
  static const int fpsPropertyKey = 56;

  /// Frames per second used to quantize keyframe times to discrete values that
  /// match this rate.
  int get fps => _fps;

  /// Change the [_fps] field value.
  /// [fpsChanged] will be invoked only if the field's value has changed.
  set fps(int value) {
    if (_fps == value) {
      return;
    }
    int from = _fps;
    _fps = value;
    onPropertyChanged(fpsPropertyKey, from, value);
    fpsChanged(from, value);
  }

  void fpsChanged(int from, int to);

  /// --------------------------------------------------------------------------
  /// Duration field with key 57.
  int _duration = 60;
  static const int durationPropertyKey = 57;

  /// Duration expressed in number of frames.
  int get duration => _duration;

  /// Change the [_duration] field value.
  /// [durationChanged] will be invoked only if the field's value has changed.
  set duration(int value) {
    if (_duration == value) {
      return;
    }
    int from = _duration;
    _duration = value;
    onPropertyChanged(durationPropertyKey, from, value);
    durationChanged(from, value);
  }

  void durationChanged(int from, int to);

  /// --------------------------------------------------------------------------
  /// Speed field with key 58.
  double _speed = 1;
  static const int speedPropertyKey = 58;

  /// Playback speed multiplier.
  double get speed => _speed;

  /// Change the [_speed] field value.
  /// [speedChanged] will be invoked only if the field's value has changed.
  set speed(double value) {
    if (_speed == value) {
      return;
    }
    double from = _speed;
    _speed = value;
    onPropertyChanged(speedPropertyKey, from, value);
    speedChanged(from, value);
  }

  void speedChanged(double from, double to);

  /// --------------------------------------------------------------------------
  /// LoopValue field with key 59.
  int _loopValue = 0;
  static const int loopValuePropertyKey = 59;

  /// Loop value option matches Loop enumeration.
  int get loopValue => _loopValue;

  /// Change the [_loopValue] field value.
  /// [loopValueChanged] will be invoked only if the field's value has changed.
  set loopValue(int value) {
    if (_loopValue == value) {
      return;
    }
    int from = _loopValue;
    _loopValue = value;
    onPropertyChanged(loopValuePropertyKey, from, value);
    loopValueChanged(from, value);
  }

  void loopValueChanged(int from, int to);

  /// --------------------------------------------------------------------------
  /// WorkStart field with key 60.
  int _workStart;
  static const int workStartPropertyKey = 60;

  /// Start of the work area in frames.
  int get workStart => _workStart;

  /// Change the [_workStart] field value.
  /// [workStartChanged] will be invoked only if the field's value has changed.
  set workStart(int value) {
    if (_workStart == value) {
      return;
    }
    int from = _workStart;
    _workStart = value;
    onPropertyChanged(workStartPropertyKey, from, value);
    workStartChanged(from, value);
  }

  void workStartChanged(int from, int to);

  /// --------------------------------------------------------------------------
  /// WorkEnd field with key 61.
  int _workEnd;
  static const int workEndPropertyKey = 61;

  /// End of the work area in frames.
  int get workEnd => _workEnd;

  /// Change the [_workEnd] field value.
  /// [workEndChanged] will be invoked only if the field's value has changed.
  set workEnd(int value) {
    if (_workEnd == value) {
      return;
    }
    int from = _workEnd;
    _workEnd = value;
    onPropertyChanged(workEndPropertyKey, from, value);
    workEndChanged(from, value);
  }

  void workEndChanged(int from, int to);

  /// --------------------------------------------------------------------------
  /// EnableWorkArea field with key 62.
  bool _enableWorkArea = false;
  static const int enableWorkAreaPropertyKey = 62;

  /// Whether or not the work area is enabled.
  bool get enableWorkArea => _enableWorkArea;

  /// Change the [_enableWorkArea] field value.
  /// [enableWorkAreaChanged] will be invoked only if the field's value has
  /// changed.
  set enableWorkArea(bool value) {
    if (_enableWorkArea == value) {
      return;
    }
    bool from = _enableWorkArea;
    _enableWorkArea = value;
    onPropertyChanged(enableWorkAreaPropertyKey, from, value);
    enableWorkAreaChanged(from, value);
  }

  void enableWorkAreaChanged(bool from, bool to);

  @override
  void changeNonNull() {
    super.changeNonNull();
    if (_fps != null) {
      onPropertyChanged(fpsPropertyKey, _fps, _fps);
    }
    if (_duration != null) {
      onPropertyChanged(durationPropertyKey, _duration, _duration);
    }
    if (_speed != null) {
      onPropertyChanged(speedPropertyKey, _speed, _speed);
    }
    if (_loopValue != null) {
      onPropertyChanged(loopValuePropertyKey, _loopValue, _loopValue);
    }
    if (_workStart != null) {
      onPropertyChanged(workStartPropertyKey, _workStart, _workStart);
    }
    if (_workEnd != null) {
      onPropertyChanged(workEndPropertyKey, _workEnd, _workEnd);
    }
    if (_enableWorkArea != null) {
      onPropertyChanged(
          enableWorkAreaPropertyKey, _enableWorkArea, _enableWorkArea);
    }
  }

  @override
  void writeRuntimeProperties(BinaryWriter writer, HashMap<Id, int> idLookup) {
    super.writeRuntimeProperties(writer, idLookup);
    if (_fps != null && exports(fpsPropertyKey)) {
      context.uintType.writeRuntimeProperty(fpsPropertyKey, writer, _fps);
    }
    if (_duration != null && exports(durationPropertyKey)) {
      context.uintType
          .writeRuntimeProperty(durationPropertyKey, writer, _duration);
    }
    if (_speed != null && exports(speedPropertyKey)) {
      context.doubleType.writeRuntimeProperty(speedPropertyKey, writer, _speed);
    }
    if (_loopValue != null && exports(loopValuePropertyKey)) {
      context.uintType
          .writeRuntimeProperty(loopValuePropertyKey, writer, _loopValue);
    }
    if (_workStart != null && exports(workStartPropertyKey)) {
      context.uintType
          .writeRuntimeProperty(workStartPropertyKey, writer, _workStart);
    }
    if (_workEnd != null && exports(workEndPropertyKey)) {
      context.uintType
          .writeRuntimeProperty(workEndPropertyKey, writer, _workEnd);
    }
    if (_enableWorkArea != null && exports(enableWorkAreaPropertyKey)) {
      context.boolType.writeRuntimeProperty(
          enableWorkAreaPropertyKey, writer, _enableWorkArea);
    }
  }

  @override
  bool exports(int propertyKey) {
    switch (propertyKey) {
      case fpsPropertyKey:
        return _fps != 60;
      case durationPropertyKey:
        return _duration != 60;
      case speedPropertyKey:
        return _speed != 1;
      case loopValuePropertyKey:
        return _loopValue != 0;
      case enableWorkAreaPropertyKey:
        return _enableWorkArea != false;
    }
    return super.exports(propertyKey);
  }

  @override
  K getProperty<K>(int propertyKey) {
    switch (propertyKey) {
      case fpsPropertyKey:
        return fps as K;
      case durationPropertyKey:
        return duration as K;
      case speedPropertyKey:
        return speed as K;
      case loopValuePropertyKey:
        return loopValue as K;
      case workStartPropertyKey:
        return workStart as K;
      case workEndPropertyKey:
        return workEnd as K;
      case enableWorkAreaPropertyKey:
        return enableWorkArea as K;
      default:
        return super.getProperty<K>(propertyKey);
    }
  }

  @override
  bool hasProperty(int propertyKey) {
    switch (propertyKey) {
      case fpsPropertyKey:
      case durationPropertyKey:
      case speedPropertyKey:
      case loopValuePropertyKey:
      case workStartPropertyKey:
      case workEndPropertyKey:
      case enableWorkAreaPropertyKey:
        return true;
      default:
        return super.hasProperty(propertyKey);
    }
  }
}
