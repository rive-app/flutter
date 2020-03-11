/// Core automatically generated lib/src/generated/node_base.dart.
/// Do not modify manually.

import 'package:meta/meta.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/src/generated/component_base.dart';
import 'package:rive_core/src/generated/container_component_base.dart';

abstract class NodeBase extends ContainerComponent {
  static const int typeKey = 2;
  @override
  int get coreType => NodeBase.typeKey;
  @override
  Set<int> get coreTypes =>
      {NodeBase.typeKey, ContainerComponentBase.typeKey, ComponentBase.typeKey};

  /// --------------------------------------------------------------------------
  /// X field with key 13.
  double _x = 0;
  static const int xPropertyKey = 13;
  double get x => _x;

  /// Change the [_x] field value.
  /// [xChanged] will be invoked only if the field's value has changed.
  set x(double value) {
    if (_x == value) {
      return;
    }
    double from = _x;
    _x = value;
    xChanged(from, value);
  }

  @mustCallSuper
  void xChanged(double from, double to) {
    onPropertyChanged(xPropertyKey, from, to);
  }

  /// --------------------------------------------------------------------------
  /// Y field with key 14.
  double _y = 0;
  static const int yPropertyKey = 14;
  double get y => _y;

  /// Change the [_y] field value.
  /// [yChanged] will be invoked only if the field's value has changed.
  set y(double value) {
    if (_y == value) {
      return;
    }
    double from = _y;
    _y = value;
    yChanged(from, value);
  }

  @mustCallSuper
  void yChanged(double from, double to) {
    onPropertyChanged(yPropertyKey, from, to);
  }

  /// --------------------------------------------------------------------------
  /// Rotation field with key 15.
  double _rotation = 0;
  static const int rotationPropertyKey = 15;
  double get rotation => _rotation;

  /// Change the [_rotation] field value.
  /// [rotationChanged] will be invoked only if the field's value has changed.
  set rotation(double value) {
    if (_rotation == value) {
      return;
    }
    double from = _rotation;
    _rotation = value;
    rotationChanged(from, value);
  }

  @mustCallSuper
  void rotationChanged(double from, double to) {
    onPropertyChanged(rotationPropertyKey, from, to);
  }

  /// --------------------------------------------------------------------------
  /// ScaleX field with key 16.
  double _scaleX = 1;
  static const int scaleXPropertyKey = 16;
  double get scaleX => _scaleX;

  /// Change the [_scaleX] field value.
  /// [scaleXChanged] will be invoked only if the field's value has changed.
  set scaleX(double value) {
    if (_scaleX == value) {
      return;
    }
    double from = _scaleX;
    _scaleX = value;
    scaleXChanged(from, value);
  }

  @mustCallSuper
  void scaleXChanged(double from, double to) {
    onPropertyChanged(scaleXPropertyKey, from, to);
  }

  /// --------------------------------------------------------------------------
  /// ScaleY field with key 17.
  double _scaleY = 1;
  static const int scaleYPropertyKey = 17;
  double get scaleY => _scaleY;

  /// Change the [_scaleY] field value.
  /// [scaleYChanged] will be invoked only if the field's value has changed.
  set scaleY(double value) {
    if (_scaleY == value) {
      return;
    }
    double from = _scaleY;
    _scaleY = value;
    scaleYChanged(from, value);
  }

  @mustCallSuper
  void scaleYChanged(double from, double to) {
    onPropertyChanged(scaleYPropertyKey, from, to);
  }

  /// --------------------------------------------------------------------------
  /// Opacity field with key 18.
  double _opacity = 1;
  static const int opacityPropertyKey = 18;
  double get opacity => _opacity;

  /// Change the [_opacity] field value.
  /// [opacityChanged] will be invoked only if the field's value has changed.
  set opacity(double value) {
    if (_opacity == value) {
      return;
    }
    double from = _opacity;
    _opacity = value;
    opacityChanged(from, value);
  }

  @mustCallSuper
  void opacityChanged(double from, double to) {
    onPropertyChanged(opacityPropertyKey, from, to);
  }

  @override
  void changeNonNull() {
    super.changeNonNull();
    if (x != null) {
      onPropertyChanged(xPropertyKey, x, x);
    }
    if (y != null) {
      onPropertyChanged(yPropertyKey, y, y);
    }
    if (rotation != null) {
      onPropertyChanged(rotationPropertyKey, rotation, rotation);
    }
    if (scaleX != null) {
      onPropertyChanged(scaleXPropertyKey, scaleX, scaleX);
    }
    if (scaleY != null) {
      onPropertyChanged(scaleYPropertyKey, scaleY, scaleY);
    }
    if (opacity != null) {
      onPropertyChanged(opacityPropertyKey, opacity, opacity);
    }
  }

  @override
  K getProperty<K>(int propertyKey) {
    switch (propertyKey) {
      case xPropertyKey:
        return x as K;
      case yPropertyKey:
        return y as K;
      case rotationPropertyKey:
        return rotation as K;
      case scaleXPropertyKey:
        return scaleX as K;
      case scaleYPropertyKey:
        return scaleY as K;
      case opacityPropertyKey:
        return opacity as K;
      default:
        return super.getProperty<K>(propertyKey);
    }
  }
}
