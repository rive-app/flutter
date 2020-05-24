/// Core automatically generated lib/src/generated/backboard_base.dart.
/// Do not modify manually.

import 'package:core/core.dart';
import 'package:rive_core/src/generated/rive_core_context.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';
import 'dart:collection';

abstract class BackboardBase<T extends RiveCoreContext> extends Core<T> {
  static const int typeKey = 23;
  @override
  int get coreType => BackboardBase.typeKey;
  @override
  Set<int> get coreTypes => {BackboardBase.typeKey};

  /// --------------------------------------------------------------------------
  /// ActiveArtboardId field with key 43.
  Id _activeArtboardId;
  static const int activeArtboardIdPropertyKey = 43;

  /// Identifier used to track the last active artboard.
  Id get activeArtboardId => _activeArtboardId;

  /// Change the [_activeArtboardId] field value.
  /// [activeArtboardIdChanged] will be invoked only if the field's value has
  /// changed.
  set activeArtboardId(Id value) {
    if (_activeArtboardId == value) {
      return;
    }
    Id from = _activeArtboardId;
    _activeArtboardId = value;
    onPropertyChanged(activeArtboardIdPropertyKey, from, value);
    activeArtboardIdChanged(from, value);
  }

  void activeArtboardIdChanged(Id from, Id to);

  /// --------------------------------------------------------------------------
  /// MainArtboardId field with key 44.
  Id _mainArtboardId;
  static const int mainArtboardIdPropertyKey = 44;

  /// Identifier used to track the  main artboard (this is the default one that
  /// shows up in runtimes unless specified).
  Id get mainArtboardId => _mainArtboardId;

  /// Change the [_mainArtboardId] field value.
  /// [mainArtboardIdChanged] will be invoked only if the field's value has
  /// changed.
  set mainArtboardId(Id value) {
    if (_mainArtboardId == value) {
      return;
    }
    Id from = _mainArtboardId;
    _mainArtboardId = value;
    onPropertyChanged(mainArtboardIdPropertyKey, from, value);
    mainArtboardIdChanged(from, value);
  }

  void mainArtboardIdChanged(Id from, Id to);

  /// --------------------------------------------------------------------------
  /// ColorValue field with key 45.
  int _colorValue = 0xFF222222;
  static const int colorValuePropertyKey = 45;

  /// The background color.
  int get colorValue => _colorValue;

  /// Change the [_colorValue] field value.
  /// [colorValueChanged] will be invoked only if the field's value has changed.
  set colorValue(int value) {
    if (_colorValue == value) {
      return;
    }
    int from = _colorValue;
    _colorValue = value;
    onPropertyChanged(colorValuePropertyKey, from, value);
    colorValueChanged(from, value);
  }

  void colorValueChanged(int from, int to);

  @override
  void changeNonNull() {
    if (activeArtboardId != null) {
      onPropertyChanged(
          activeArtboardIdPropertyKey, activeArtboardId, activeArtboardId);
    }
    if (mainArtboardId != null) {
      onPropertyChanged(
          mainArtboardIdPropertyKey, mainArtboardId, mainArtboardId);
    }
    if (colorValue != null) {
      onPropertyChanged(colorValuePropertyKey, colorValue, colorValue);
    }
  }

  @override
  void writeRuntimeProperties(BinaryWriter writer, HashMap<Id, int> idLookup) {
    if (_activeArtboardId != null) {
      var value = idLookup[_activeArtboardId];
      assert(value != null);
      context.intType.write(writer, value);
    }
    if (_mainArtboardId != null) {
      var value = idLookup[_mainArtboardId];
      assert(value != null);
      context.intType.write(writer, value);
    }
    if (_colorValue != null) {
      context.intType.write(writer, _colorValue);
    }
  }

  @override
  K getProperty<K>(int propertyKey) {
    switch (propertyKey) {
      case activeArtboardIdPropertyKey:
        return activeArtboardId as K;
      case mainArtboardIdPropertyKey:
        return mainArtboardId as K;
      case colorValuePropertyKey:
        return colorValue as K;
      default:
        return super.getProperty<K>(propertyKey);
    }
  }

  @override
  bool hasProperty(int propertyKey) {
    switch (propertyKey) {
      case activeArtboardIdPropertyKey:
      case mainArtboardIdPropertyKey:
      case colorValuePropertyKey:
        return true;
      default:
        return super.hasProperty(propertyKey);
    }
  }
}
