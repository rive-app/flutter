/// Core automatically generated lib/src/generated/node_base.dart.
/// Do not modify manually.

import 'dart:collection';
import 'package:core/core.dart';
import 'package:core/field_types/core_field_type.dart';
import 'package:core/key_state.dart';
import 'package:rive_core/src/generated/component_base.dart';
import 'package:rive_core/src/generated/container_component_base.dart';
import 'package:rive_core/src/generated/transform_component_base.dart';
import 'package:rive_core/transform_component.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

abstract class NodeBase extends TransformComponent {
  static const int typeKey = 2;
  @override
  int get coreType => NodeBase.typeKey;
  @override
  Set<int> get coreTypes => {
        NodeBase.typeKey,
        TransformComponentBase.typeKey,
        ContainerComponentBase.typeKey,
        ComponentBase.typeKey
      };

  /// --------------------------------------------------------------------------
  /// X field with key 13.
  double _x = 0;
  double _xAnimated;
  KeyState _xKeyState = KeyState.none;
  static const int xPropertyKey = 13;

  /// Get the [_x] field value.Note this may not match the core value if
  /// animation mode is active.
  @override
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

  @override
  set x(double value) {
    if (x == value) {
      return;
    }
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
  @override
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

  @override
  set y(double value) {
    if (y == value) {
      return;
    }
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

  @override
  void changeNonNull() {
    super.changeNonNull();
    if (_x != null) {
      onPropertyChanged(xPropertyKey, _x, _x);
    }
    if (_y != null) {
      onPropertyChanged(yPropertyKey, _y, _y);
    }
  }

  @override
  void writeRuntimeProperties(BinaryWriter writer,
      HashMap<int, CoreFieldType> propertyToField, HashMap<Id, int> idLookup) {
    super.writeRuntimeProperties(writer, propertyToField, idLookup);
    if (_x != null && exports(xPropertyKey)) {
      context.doubleType
          .writeRuntimeProperty(xPropertyKey, writer, _x, propertyToField);
    }
    if (_y != null && exports(yPropertyKey)) {
      context.doubleType
          .writeRuntimeProperty(yPropertyKey, writer, _y, propertyToField);
    }
  }

  @override
  bool exports(int propertyKey) {
    switch (propertyKey) {
      case xPropertyKey:
        return _x != 0;
      case yPropertyKey:
        return _y != 0;
    }
    return super.exports(propertyKey);
  }

  @override
  K getProperty<K>(int propertyKey) {
    switch (propertyKey) {
      case xPropertyKey:
        return x as K;
      case yPropertyKey:
        return y as K;
      default:
        return super.getProperty<K>(propertyKey);
    }
  }

  @override
  bool hasProperty(int propertyKey) {
    switch (propertyKey) {
      case xPropertyKey:
      case yPropertyKey:
        return true;
      default:
        return super.hasProperty(propertyKey);
    }
  }
}
