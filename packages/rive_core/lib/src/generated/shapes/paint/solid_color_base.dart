/// Core automatically generated
/// lib/src/generated/shapes/paint/solid_color_base.dart.
/// Do not modify manually.

import 'package:meta/meta.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/src/generated/component_base.dart';

abstract class SolidColorBase extends Component {
  static const int typeKey = 18;
  @override
  int get coreType => SolidColorBase.typeKey;
  @override
  Set<int> get coreTypes => {SolidColorBase.typeKey, ComponentBase.typeKey};

  /// --------------------------------------------------------------------------
  /// ColorValue field with key 37.
  int _colorValue = 0xFFFFFFFF;
  static const int colorValuePropertyKey = 37;
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

  @override
  void changeNonNull() {
    super.changeNonNull();
    if (colorValue != null) {
      onPropertyChanged(colorValuePropertyKey, colorValue, colorValue);
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
}
