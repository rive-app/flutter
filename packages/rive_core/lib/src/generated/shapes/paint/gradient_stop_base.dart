/// Core automatically generated
/// lib/src/generated/shapes/paint/gradient_stop_base.dart.
/// Do not modify manually.

import 'dart:collection';
import 'package:core/core.dart';
import 'package:core/key_state.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/src/generated/component_base.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

abstract class GradientStopBase extends Component {
  static const int typeKey = 19;
  @override
  int get coreType => GradientStopBase.typeKey;
  @override
  Set<int> get coreTypes => {GradientStopBase.typeKey, ComponentBase.typeKey};

  /// --------------------------------------------------------------------------
  /// ColorValue field with key 38.
  int _colorValue = 0xFFFFFFFF;
  int _colorValueAnimated;
  KeyState _colorValueKeyState = KeyState.none;
  static const int colorValuePropertyKey = 38;

  /// Get the [_colorValue] field value.Note this may not match the core value
  /// if animation mode is active.
  int get colorValue => _colorValueAnimated ?? _colorValue;

  /// Get the non-animation [_colorValue] field value.
  int get colorValueCore => _colorValue;

  /// Change the [_colorValue] field value.
  /// [colorValueChanged] will be invoked only if the field's value has changed.
  set colorValueCore(int value) {
    if (_colorValue == value) {
      return;
    }
    int from = _colorValue;
    _colorValue = value;
    onPropertyChanged(colorValuePropertyKey, from, value);
    colorValueChanged(from, value);
  }

  set colorValue(int value) {
    if (colorValue == value) {
      return;
    }
    if (context != null && context.isAnimating) {
      _colorValueAnimate(value, true);
      return;
    }
    colorValueCore = value;
  }

  void _colorValueAnimate(int value, bool autoKey) {
    if (_colorValueAnimated == value) {
      return;
    }
    int from = colorValue;
    _colorValueAnimated = value;
    int to = colorValue;
    onAnimatedPropertyChanged(colorValuePropertyKey, autoKey, from, to);
    colorValueChanged(from, to);
  }

  int get colorValueAnimated => _colorValueAnimated;
  set colorValueAnimated(int value) => _colorValueAnimate(value, false);
  KeyState get colorValueKeyState => _colorValueKeyState;
  set colorValueKeyState(KeyState value) {
    if (_colorValueKeyState == value) {
      return;
    }
    _colorValueKeyState = value;
    // Force update anything listening on this property.
    onAnimatedPropertyChanged(
        colorValuePropertyKey, false, _colorValueAnimated, _colorValueAnimated);
  }

  void colorValueChanged(int from, int to);

  /// --------------------------------------------------------------------------
  /// Position field with key 39.
  double _position = 0;
  double _positionAnimated;
  KeyState _positionKeyState = KeyState.none;
  static const int positionPropertyKey = 39;

  /// Get the [_position] field value.Note this may not match the core value if
  /// animation mode is active.
  double get position => _positionAnimated ?? _position;

  /// Get the non-animation [_position] field value.
  double get positionCore => _position;

  /// Change the [_position] field value.
  /// [positionChanged] will be invoked only if the field's value has changed.
  set positionCore(double value) {
    if (_position == value) {
      return;
    }
    double from = _position;
    _position = value;
    onPropertyChanged(positionPropertyKey, from, value);
    positionChanged(from, value);
  }

  set position(double value) {
    if (position == value) {
      return;
    }
    if (context != null && context.isAnimating) {
      _positionAnimate(value, true);
      return;
    }
    positionCore = value;
  }

  void _positionAnimate(double value, bool autoKey) {
    if (_positionAnimated == value) {
      return;
    }
    double from = position;
    _positionAnimated = value;
    double to = position;
    onAnimatedPropertyChanged(positionPropertyKey, autoKey, from, to);
    positionChanged(from, to);
  }

  double get positionAnimated => _positionAnimated;
  set positionAnimated(double value) => _positionAnimate(value, false);
  KeyState get positionKeyState => _positionKeyState;
  set positionKeyState(KeyState value) {
    if (_positionKeyState == value) {
      return;
    }
    _positionKeyState = value;
    // Force update anything listening on this property.
    onAnimatedPropertyChanged(
        positionPropertyKey, false, _positionAnimated, _positionAnimated);
  }

  void positionChanged(double from, double to);

  @override
  void changeNonNull() {
    super.changeNonNull();
    if (colorValue != null) {
      onPropertyChanged(colorValuePropertyKey, colorValue, colorValue);
    }
    if (position != null) {
      onPropertyChanged(positionPropertyKey, position, position);
    }
  }

  @override
  void writeRuntimeProperties(BinaryWriter writer, HashMap<Id, int> idLookup) {
    super.writeRuntimeProperties(writer, idLookup);
    if (_colorValue != null) {
      context.colorType
          .writeProperty(colorValuePropertyKey, writer, _colorValue);
    }
    if (_position != null) {
      context.doubleType.writeProperty(positionPropertyKey, writer, _position);
    }
  }

  @override
  K getProperty<K>(int propertyKey) {
    switch (propertyKey) {
      case colorValuePropertyKey:
        return colorValue as K;
      case positionPropertyKey:
        return position as K;
      default:
        return super.getProperty<K>(propertyKey);
    }
  }

  @override
  bool hasProperty(int propertyKey) {
    switch (propertyKey) {
      case colorValuePropertyKey:
      case positionPropertyKey:
        return true;
      default:
        return super.hasProperty(propertyKey);
    }
  }
}
