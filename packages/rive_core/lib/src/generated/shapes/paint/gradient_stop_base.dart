/// Core automatically generated
/// lib/src/generated/shapes/paint/gradient_stop_base.dart.
/// Do not modify manually.

import 'package:meta/meta.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/src/generated/component_base.dart';

abstract class GradientStopBase extends Component {
  static const int typeKey = 19;
  @override
  int get coreType => GradientStopBase.typeKey;
  @override
  Set<int> get coreTypes => {GradientStopBase.typeKey, ComponentBase.typeKey};

  /// --------------------------------------------------------------------------
  /// ColorValue field with key 38.
  int _colorValue = 0xFFFFFFFF;
  static const int colorValuePropertyKey = 38;
  int get colorValue => _colorValue;

  /// Change the [_colorValue] field value.
  /// [colorValueChanged] will be invoked only if the field's value has changed.
  set colorValue(int value) {
    if (_colorValue == value) {
      return;
    }
    int from = _colorValue;
    _colorValue = value;
    colorValueChanged(from, value);
  }

  @mustCallSuper
  void colorValueChanged(int from, int to) {
    onPropertyChanged(colorValuePropertyKey, from, to);
  }

  /// --------------------------------------------------------------------------
  /// Position field with key 39.
  double _position = 0;
  static const int positionPropertyKey = 39;
  double get position => _position;

  /// Change the [_position] field value.
  /// [positionChanged] will be invoked only if the field's value has changed.
  set position(double value) {
    if (_position == value) {
      return;
    }
    double from = _position;
    _position = value;
    positionChanged(from, value);
  }

  @mustCallSuper
  void positionChanged(double from, double to) {
    onPropertyChanged(positionPropertyKey, from, to);
  }

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
}
