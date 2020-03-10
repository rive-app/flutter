/// Core automatically generated
/// lib/src/generated/shapes/paint/shape_paint_base.dart.
/// Do not modify manually.

import 'package:meta/meta.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/src/generated/component_base.dart';
import 'package:rive_core/src/generated/container_component_base.dart';

abstract class ShapePaintBase extends ContainerComponent {
  static const int typeKey = 21;
  @override
  int get coreType => ShapePaintBase.typeKey;
  @override
  Set<int> get coreTypes => {
        ShapePaintBase.typeKey,
        ContainerComponentBase.typeKey,
        ComponentBase.typeKey
      };

  /// --------------------------------------------------------------------------
  /// IsVisible field with key 41.
  bool _isVisible = true;
  static const int isVisiblePropertyKey = 41;
  bool get isVisible => _isVisible;

  /// Change the [_isVisible] field value.
  /// [isVisibleChanged] will be invoked only if the field's value has changed.
  set isVisible(bool value) {
    if (_isVisible == value) {
      return;
    }
    bool from = _isVisible;
    _isVisible = value;
    isVisibleChanged(from, value);
  }

  @mustCallSuper
  void isVisibleChanged(bool from, bool to) {
    onPropertyChanged(isVisiblePropertyKey, from, to);
  }

  @override
  void changeNonNull() {
    super.changeNonNull();
    if (isVisible != null) {
      onPropertyChanged(isVisiblePropertyKey, isVisible, isVisible);
    }
  }

  @override
  K getProperty<K>(int propertyKey) {
    switch (propertyKey) {
      case isVisiblePropertyKey:
        return isVisible as K;
      default:
        return super.getProperty<K>(propertyKey);
    }
  }
}
