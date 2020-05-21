/// Core automatically generated lib/src/generated/node_base.dart.
/// Do not modify manually.

import 'package:core/key_state.dart';
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
  double _xAnimated;
  KeyState _xKeyState = KeyState.none;
  static const int xPropertyKey = 13;

  /// Get the [_x] field value.Note this may not match the core value if
  /// animation mode is active.
  double get x => _xAnimated ?? _x;

  /// Get the non-animation [_x] field value.
  double get xCore => _x;

  /// Change the [_x] field value.
  /// [xChanged] will be invoked only if the field's value has changed.
  set xCore(double value) {
    if (_x == value) {
      return;
    }
    double from = _x;
    _x = value;
    onPropertyChanged(xPropertyKey, from, value);
    xChanged(from, value);
  }

  set x(double value) {
    if (context != null && context.isAnimating) {
      _xAnimate(value, true);
      return;
    }
    xCore = value;
  }

  void _xAnimate(double value, bool autoKey) {
    if (_xAnimated == value) {
      return;
    }
    double from = x;
    _xAnimated = value;
    double to = x;
    onAnimatedPropertyChanged(xPropertyKey, autoKey, from, to);
    xChanged(from, to);
  }

  double get xAnimated => _xAnimated;
  set xAnimated(double value) => _xAnimate(value, false);
  KeyState get xKeyState => _xKeyState;
  set xKeyState(KeyState value) {
    if (_xKeyState == value) {
      return;
    }
    _xKeyState = value;
    // Force update anything listening on this property.
    onAnimatedPropertyChanged(xPropertyKey, false, _xAnimated, _xAnimated);
  }

  void xChanged(double from, double to);

  /// --------------------------------------------------------------------------
  /// Y field with key 14.
  double _y = 0;
  double _yAnimated;
  KeyState _yKeyState = KeyState.none;
  static const int yPropertyKey = 14;

  /// Get the [_y] field value.Note this may not match the core value if
  /// animation mode is active.
  double get y => _yAnimated ?? _y;

  /// Get the non-animation [_y] field value.
  double get yCore => _y;

  /// Change the [_y] field value.
  /// [yChanged] will be invoked only if the field's value has changed.
  set yCore(double value) {
    if (_y == value) {
      return;
    }
    double from = _y;
    _y = value;
    onPropertyChanged(yPropertyKey, from, value);
    yChanged(from, value);
  }

  set y(double value) {
    if (context != null && context.isAnimating) {
      _yAnimate(value, true);
      return;
    }
    yCore = value;
  }

  void _yAnimate(double value, bool autoKey) {
    if (_yAnimated == value) {
      return;
    }
    double from = y;
    _yAnimated = value;
    double to = y;
    onAnimatedPropertyChanged(yPropertyKey, autoKey, from, to);
    yChanged(from, to);
  }

  double get yAnimated => _yAnimated;
  set yAnimated(double value) => _yAnimate(value, false);
  KeyState get yKeyState => _yKeyState;
  set yKeyState(KeyState value) {
    if (_yKeyState == value) {
      return;
    }
    _yKeyState = value;
    // Force update anything listening on this property.
    onAnimatedPropertyChanged(yPropertyKey, false, _yAnimated, _yAnimated);
  }

  void yChanged(double from, double to);

  /// --------------------------------------------------------------------------
  /// Rotation field with key 15.
  double _rotation = 0;
  double _rotationAnimated;
  KeyState _rotationKeyState = KeyState.none;
  static const int rotationPropertyKey = 15;

  /// Get the [_rotation] field value.Note this may not match the core value if
  /// animation mode is active.
  double get rotation => _rotationAnimated ?? _rotation;

  /// Get the non-animation [_rotation] field value.
  double get rotationCore => _rotation;

  /// Change the [_rotation] field value.
  /// [rotationChanged] will be invoked only if the field's value has changed.
  set rotationCore(double value) {
    if (_rotation == value) {
      return;
    }
    double from = _rotation;
    _rotation = value;
    onPropertyChanged(rotationPropertyKey, from, value);
    rotationChanged(from, value);
  }

  set rotation(double value) {
    if (context != null && context.isAnimating) {
      _rotationAnimate(value, true);
      return;
    }
    rotationCore = value;
  }

  void _rotationAnimate(double value, bool autoKey) {
    if (_rotationAnimated == value) {
      return;
    }
    double from = rotation;
    _rotationAnimated = value;
    double to = rotation;
    onAnimatedPropertyChanged(rotationPropertyKey, autoKey, from, to);
    rotationChanged(from, to);
  }

  double get rotationAnimated => _rotationAnimated;
  set rotationAnimated(double value) => _rotationAnimate(value, false);
  KeyState get rotationKeyState => _rotationKeyState;
  set rotationKeyState(KeyState value) {
    if (_rotationKeyState == value) {
      return;
    }
    _rotationKeyState = value;
    // Force update anything listening on this property.
    onAnimatedPropertyChanged(
        rotationPropertyKey, false, _rotationAnimated, _rotationAnimated);
  }

  void rotationChanged(double from, double to);

  /// --------------------------------------------------------------------------
  /// ScaleX field with key 16.
  double _scaleX = 1;
  double _scaleXAnimated;
  KeyState _scaleXKeyState = KeyState.none;
  static const int scaleXPropertyKey = 16;

  /// Get the [_scaleX] field value.Note this may not match the core value if
  /// animation mode is active.
  double get scaleX => _scaleXAnimated ?? _scaleX;

  /// Get the non-animation [_scaleX] field value.
  double get scaleXCore => _scaleX;

  /// Change the [_scaleX] field value.
  /// [scaleXChanged] will be invoked only if the field's value has changed.
  set scaleXCore(double value) {
    if (_scaleX == value) {
      return;
    }
    double from = _scaleX;
    _scaleX = value;
    onPropertyChanged(scaleXPropertyKey, from, value);
    scaleXChanged(from, value);
  }

  set scaleX(double value) {
    if (context != null && context.isAnimating) {
      _scaleXAnimate(value, true);
      return;
    }
    scaleXCore = value;
  }

  void _scaleXAnimate(double value, bool autoKey) {
    if (_scaleXAnimated == value) {
      return;
    }
    double from = scaleX;
    _scaleXAnimated = value;
    double to = scaleX;
    onAnimatedPropertyChanged(scaleXPropertyKey, autoKey, from, to);
    scaleXChanged(from, to);
  }

  double get scaleXAnimated => _scaleXAnimated;
  set scaleXAnimated(double value) => _scaleXAnimate(value, false);
  KeyState get scaleXKeyState => _scaleXKeyState;
  set scaleXKeyState(KeyState value) {
    if (_scaleXKeyState == value) {
      return;
    }
    _scaleXKeyState = value;
    // Force update anything listening on this property.
    onAnimatedPropertyChanged(
        scaleXPropertyKey, false, _scaleXAnimated, _scaleXAnimated);
  }

  void scaleXChanged(double from, double to);

  /// --------------------------------------------------------------------------
  /// ScaleY field with key 17.
  double _scaleY = 1;
  double _scaleYAnimated;
  KeyState _scaleYKeyState = KeyState.none;
  static const int scaleYPropertyKey = 17;

  /// Get the [_scaleY] field value.Note this may not match the core value if
  /// animation mode is active.
  double get scaleY => _scaleYAnimated ?? _scaleY;

  /// Get the non-animation [_scaleY] field value.
  double get scaleYCore => _scaleY;

  /// Change the [_scaleY] field value.
  /// [scaleYChanged] will be invoked only if the field's value has changed.
  set scaleYCore(double value) {
    if (_scaleY == value) {
      return;
    }
    double from = _scaleY;
    _scaleY = value;
    onPropertyChanged(scaleYPropertyKey, from, value);
    scaleYChanged(from, value);
  }

  set scaleY(double value) {
    if (context != null && context.isAnimating) {
      _scaleYAnimate(value, true);
      return;
    }
    scaleYCore = value;
  }

  void _scaleYAnimate(double value, bool autoKey) {
    if (_scaleYAnimated == value) {
      return;
    }
    double from = scaleY;
    _scaleYAnimated = value;
    double to = scaleY;
    onAnimatedPropertyChanged(scaleYPropertyKey, autoKey, from, to);
    scaleYChanged(from, to);
  }

  double get scaleYAnimated => _scaleYAnimated;
  set scaleYAnimated(double value) => _scaleYAnimate(value, false);
  KeyState get scaleYKeyState => _scaleYKeyState;
  set scaleYKeyState(KeyState value) {
    if (_scaleYKeyState == value) {
      return;
    }
    _scaleYKeyState = value;
    // Force update anything listening on this property.
    onAnimatedPropertyChanged(
        scaleYPropertyKey, false, _scaleYAnimated, _scaleYAnimated);
  }

  void scaleYChanged(double from, double to);

  /// --------------------------------------------------------------------------
  /// Opacity field with key 18.
  double _opacity = 1;
  double _opacityAnimated;
  KeyState _opacityKeyState = KeyState.none;
  static const int opacityPropertyKey = 18;

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

  @override
  bool hasProperty(int propertyKey) {
    switch (propertyKey) {
      case xPropertyKey:
      case yPropertyKey:
      case rotationPropertyKey:
      case scaleXPropertyKey:
      case scaleYPropertyKey:
      case opacityPropertyKey:
        return true;
      default:
        return super.hasProperty(propertyKey);
    }
  }
}
