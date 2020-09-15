/// Core automatically generated
/// lib/src/generated/shapes/paint/linear_gradient_base.dart.
/// Do not modify manually.

import 'dart:collection';
import 'package:core/core.dart';
import 'package:core/field_types/core_field_type.dart';
import 'package:core/key_state.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/src/generated/component_base.dart';
import 'package:rive_core/src/generated/container_component_base.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

abstract class LinearGradientBase extends ContainerComponent {
  static const int typeKey = 22;
  @override
  int get coreType => LinearGradientBase.typeKey;
  @override
  Set<int> get coreTypes => {
        LinearGradientBase.typeKey,
        ContainerComponentBase.typeKey,
        ComponentBase.typeKey
      };

  /// --------------------------------------------------------------------------
  /// StartX field with key 42.
  double _startX = 0;
  double _startXAnimated;
  KeyState _startXKeyState = KeyState.none;
  static const int startXPropertyKey = 42;

  /// Get the [_startX] field value.Note this may not match the core value if
  /// animation mode is active.
  double get startX => _startXAnimated ?? _startX;

  /// Get the non-animation [_startX] field value.
  double get startXCore => _startX;

  /// Change the [_startX] field value.
  /// [startXChanged] will be invoked only if the field's value has changed.
  set startXCore(double value) {
    if (_startX == value) {
      return;
    }
    double from = _startX;
    _startX = value;
    onPropertyChanged(startXPropertyKey, from, value);
    startXChanged(from, value);
  }

  set startX(double value) {
    if (startX == value) {
      return;
    }
    if (context != null && context.isAnimating) {
      _startXAnimate(value, true);
      return;
    }
    startXCore = value;
  }

  void _startXAnimate(double value, bool autoKey) {
    if (_startXAnimated == value) {
      return;
    }
    double from = startX;
    _startXAnimated = value;
    double to = startX;
    onAnimatedPropertyChanged(startXPropertyKey, autoKey, from, to);
    startXChanged(from, to);
  }

  double get startXAnimated => _startXAnimated;
  set startXAnimated(double value) => _startXAnimate(value, false);
  KeyState get startXKeyState => _startXKeyState;
  set startXKeyState(KeyState value) {
    if (_startXKeyState == value) {
      return;
    }
    _startXKeyState = value;
    // Force update anything listening on this property.
    onAnimatedPropertyChanged(
        startXPropertyKey, false, _startXAnimated, _startXAnimated);
  }

  void startXChanged(double from, double to);

  /// --------------------------------------------------------------------------
  /// StartY field with key 33.
  double _startY = 0;
  double _startYAnimated;
  KeyState _startYKeyState = KeyState.none;
  static const int startYPropertyKey = 33;

  /// Get the [_startY] field value.Note this may not match the core value if
  /// animation mode is active.
  double get startY => _startYAnimated ?? _startY;

  /// Get the non-animation [_startY] field value.
  double get startYCore => _startY;

  /// Change the [_startY] field value.
  /// [startYChanged] will be invoked only if the field's value has changed.
  set startYCore(double value) {
    if (_startY == value) {
      return;
    }
    double from = _startY;
    _startY = value;
    onPropertyChanged(startYPropertyKey, from, value);
    startYChanged(from, value);
  }

  set startY(double value) {
    if (startY == value) {
      return;
    }
    if (context != null && context.isAnimating) {
      _startYAnimate(value, true);
      return;
    }
    startYCore = value;
  }

  void _startYAnimate(double value, bool autoKey) {
    if (_startYAnimated == value) {
      return;
    }
    double from = startY;
    _startYAnimated = value;
    double to = startY;
    onAnimatedPropertyChanged(startYPropertyKey, autoKey, from, to);
    startYChanged(from, to);
  }

  double get startYAnimated => _startYAnimated;
  set startYAnimated(double value) => _startYAnimate(value, false);
  KeyState get startYKeyState => _startYKeyState;
  set startYKeyState(KeyState value) {
    if (_startYKeyState == value) {
      return;
    }
    _startYKeyState = value;
    // Force update anything listening on this property.
    onAnimatedPropertyChanged(
        startYPropertyKey, false, _startYAnimated, _startYAnimated);
  }

  void startYChanged(double from, double to);

  /// --------------------------------------------------------------------------
  /// EndX field with key 34.
  double _endX = 0;
  double _endXAnimated;
  KeyState _endXKeyState = KeyState.none;
  static const int endXPropertyKey = 34;

  /// Get the [_endX] field value.Note this may not match the core value if
  /// animation mode is active.
  double get endX => _endXAnimated ?? _endX;

  /// Get the non-animation [_endX] field value.
  double get endXCore => _endX;

  /// Change the [_endX] field value.
  /// [endXChanged] will be invoked only if the field's value has changed.
  set endXCore(double value) {
    if (_endX == value) {
      return;
    }
    double from = _endX;
    _endX = value;
    onPropertyChanged(endXPropertyKey, from, value);
    endXChanged(from, value);
  }

  set endX(double value) {
    if (endX == value) {
      return;
    }
    if (context != null && context.isAnimating) {
      _endXAnimate(value, true);
      return;
    }
    endXCore = value;
  }

  void _endXAnimate(double value, bool autoKey) {
    if (_endXAnimated == value) {
      return;
    }
    double from = endX;
    _endXAnimated = value;
    double to = endX;
    onAnimatedPropertyChanged(endXPropertyKey, autoKey, from, to);
    endXChanged(from, to);
  }

  double get endXAnimated => _endXAnimated;
  set endXAnimated(double value) => _endXAnimate(value, false);
  KeyState get endXKeyState => _endXKeyState;
  set endXKeyState(KeyState value) {
    if (_endXKeyState == value) {
      return;
    }
    _endXKeyState = value;
    // Force update anything listening on this property.
    onAnimatedPropertyChanged(
        endXPropertyKey, false, _endXAnimated, _endXAnimated);
  }

  void endXChanged(double from, double to);

  /// --------------------------------------------------------------------------
  /// EndY field with key 35.
  double _endY = 0;
  double _endYAnimated;
  KeyState _endYKeyState = KeyState.none;
  static const int endYPropertyKey = 35;

  /// Get the [_endY] field value.Note this may not match the core value if
  /// animation mode is active.
  double get endY => _endYAnimated ?? _endY;

  /// Get the non-animation [_endY] field value.
  double get endYCore => _endY;

  /// Change the [_endY] field value.
  /// [endYChanged] will be invoked only if the field's value has changed.
  set endYCore(double value) {
    if (_endY == value) {
      return;
    }
    double from = _endY;
    _endY = value;
    onPropertyChanged(endYPropertyKey, from, value);
    endYChanged(from, value);
  }

  set endY(double value) {
    if (endY == value) {
      return;
    }
    if (context != null && context.isAnimating) {
      _endYAnimate(value, true);
      return;
    }
    endYCore = value;
  }

  void _endYAnimate(double value, bool autoKey) {
    if (_endYAnimated == value) {
      return;
    }
    double from = endY;
    _endYAnimated = value;
    double to = endY;
    onAnimatedPropertyChanged(endYPropertyKey, autoKey, from, to);
    endYChanged(from, to);
  }

  double get endYAnimated => _endYAnimated;
  set endYAnimated(double value) => _endYAnimate(value, false);
  KeyState get endYKeyState => _endYKeyState;
  set endYKeyState(KeyState value) {
    if (_endYKeyState == value) {
      return;
    }
    _endYKeyState = value;
    // Force update anything listening on this property.
    onAnimatedPropertyChanged(
        endYPropertyKey, false, _endYAnimated, _endYAnimated);
  }

  void endYChanged(double from, double to);

  /// --------------------------------------------------------------------------
  /// Opacity field with key 46.
  double _opacity = 1;
  double _opacityAnimated;
  KeyState _opacityKeyState = KeyState.none;
  static const int opacityPropertyKey = 46;

  /// Get the [_opacity] field value.Note this may not match the core value if
  /// animation mode is active.
  double get opacity => _opacityAnimated ?? _opacity;

  /// Get the non-animation [_opacity] field value.
  double get opacityCore => _opacity;

  /// Change the [_opacity] field value.
  /// [opacityChanged] will be invoked only if the field's value has changed.
  set opacityCore(double value) {
    if (_opacity == value) {
      return;
    }
    double from = _opacity;
    _opacity = value;
    onPropertyChanged(opacityPropertyKey, from, value);
    opacityChanged(from, value);
  }

  set opacity(double value) {
    if (opacity == value) {
      return;
    }
    if (context != null && context.isAnimating) {
      _opacityAnimate(value, true);
      return;
    }
    opacityCore = value;
  }

  void _opacityAnimate(double value, bool autoKey) {
    if (_opacityAnimated == value) {
      return;
    }
    double from = opacity;
    _opacityAnimated = value;
    double to = opacity;
    onAnimatedPropertyChanged(opacityPropertyKey, autoKey, from, to);
    opacityChanged(from, to);
  }

  double get opacityAnimated => _opacityAnimated;
  set opacityAnimated(double value) => _opacityAnimate(value, false);
  KeyState get opacityKeyState => _opacityKeyState;
  set opacityKeyState(KeyState value) {
    if (_opacityKeyState == value) {
      return;
    }
    _opacityKeyState = value;
    // Force update anything listening on this property.
    onAnimatedPropertyChanged(
        opacityPropertyKey, false, _opacityAnimated, _opacityAnimated);
  }

  void opacityChanged(double from, double to);

  @override
  void changeNonNull() {
    super.changeNonNull();
    if (_startX != null) {
      onPropertyChanged(startXPropertyKey, _startX, _startX);
    }
    if (_startY != null) {
      onPropertyChanged(startYPropertyKey, _startY, _startY);
    }
    if (_endX != null) {
      onPropertyChanged(endXPropertyKey, _endX, _endX);
    }
    if (_endY != null) {
      onPropertyChanged(endYPropertyKey, _endY, _endY);
    }
    if (_opacity != null) {
      onPropertyChanged(opacityPropertyKey, _opacity, _opacity);
    }
  }

  @override
  void writeRuntimeProperties(BinaryWriter writer,
      HashMap<int, CoreFieldType> propertyToField, HashMap<Id, int> idLookup) {
    super.writeRuntimeProperties(writer, propertyToField, idLookup);
    if (_startX != null && exports(startXPropertyKey)) {
      context.doubleType.writeRuntimeProperty(
          startXPropertyKey, writer, _startX, propertyToField);
    }
    if (_startY != null && exports(startYPropertyKey)) {
      context.doubleType.writeRuntimeProperty(
          startYPropertyKey, writer, _startY, propertyToField);
    }
    if (_endX != null && exports(endXPropertyKey)) {
      context.doubleType.writeRuntimeProperty(
          endXPropertyKey, writer, _endX, propertyToField);
    }
    if (_endY != null && exports(endYPropertyKey)) {
      context.doubleType.writeRuntimeProperty(
          endYPropertyKey, writer, _endY, propertyToField);
    }
    if (_opacity != null && exports(opacityPropertyKey)) {
      context.doubleType.writeRuntimeProperty(
          opacityPropertyKey, writer, _opacity, propertyToField);
    }
  }

  @override
  bool exports(int propertyKey) {
    switch (propertyKey) {
      case startXPropertyKey:
        return _startX != 0;
      case startYPropertyKey:
        return _startY != 0;
      case endXPropertyKey:
        return _endX != 0;
      case endYPropertyKey:
        return _endY != 0;
      case opacityPropertyKey:
        return _opacity != 1;
    }
    return super.exports(propertyKey);
  }

  @override
  K getProperty<K>(int propertyKey) {
    switch (propertyKey) {
      case startXPropertyKey:
        return startX as K;
      case startYPropertyKey:
        return startY as K;
      case endXPropertyKey:
        return endX as K;
      case endYPropertyKey:
        return endY as K;
      case opacityPropertyKey:
        return opacity as K;
      default:
        return super.getProperty<K>(propertyKey);
    }
  }

  @override
  bool hasProperty(int propertyKey) {
    switch (propertyKey) {
      case startXPropertyKey:
      case startYPropertyKey:
      case endXPropertyKey:
      case endYPropertyKey:
      case opacityPropertyKey:
        return true;
      default:
        return super.hasProperty(propertyKey);
    }
  }
}
