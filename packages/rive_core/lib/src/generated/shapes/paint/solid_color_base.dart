/// Core automatically generated
/// lib/src/generated/shapes/paint/solid_color_base.dart.
/// Do not modify manually.

import 'dart:collection';
import 'package:core/core.dart';
import 'package:core/key_state.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/src/generated/component_base.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

abstract class SolidColorBase extends Component {
  static const int typeKey = 18;
  @override
  int get coreType => SolidColorBase.typeKey;
  @override
  Set<int> get coreTypes => {SolidColorBase.typeKey, ComponentBase.typeKey};

  /// --------------------------------------------------------------------------
  /// ColorValue field with key 37.
  int _colorValue = 0xFF747474;
  int _colorValueAnimated;
  KeyState _colorValueKeyState = KeyState.none;
  static const int colorValuePropertyKey = 37;

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
    if (context != null && context.isAnimating && colorValue != value) {
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

  @override
  void changeNonNull() {
    super.changeNonNull();
    if (colorValue != null) {
      onPropertyChanged(colorValuePropertyKey, colorValue, colorValue);
    }
  }

  @override
  void writeRuntimeProperties(BinaryWriter writer, HashMap<Id, int> idLookup) {
    super.writeRuntimeProperties(writer, idLookup);
    if (_colorValue != null) {
      context.colorType
          .writeProperty(colorValuePropertyKey, writer, _colorValue);
    }
  }

  @override
  K getProperty<K>(int propertyKey) {
    switch (propertyKey) {
      case colorValuePropertyKey:
        return colorValue as K;
      default:
        return super.getProperty<K>(propertyKey);
    }
  }

  @override
  bool hasProperty(int propertyKey) {
    switch (propertyKey) {
      case colorValuePropertyKey:
        return true;
      default:
        return super.hasProperty(propertyKey);
    }
  }
}
