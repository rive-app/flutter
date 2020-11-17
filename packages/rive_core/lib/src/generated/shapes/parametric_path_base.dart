/// Core automatically generated
/// lib/src/generated/shapes/parametric_path_base.dart.
/// Do not modify manually.

import 'dart:collection';
import 'package:core/core.dart';
import 'package:core/field_types/core_field_type.dart';
import 'package:core/key_state.dart';
import 'package:rive_core/shapes/path.dart';
import 'package:rive_core/src/generated/component_base.dart';
import 'package:rive_core/src/generated/container_component_base.dart';
import 'package:rive_core/src/generated/node_base.dart';
import 'package:rive_core/src/generated/shapes/path_base.dart';
import 'package:rive_core/src/generated/transform_component_base.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

abstract class ParametricPathBase extends Path {
  static const int typeKey = 15;
  @override
  int get coreType => ParametricPathBase.typeKey;
  @override
  Set<int> get coreTypes => {
        ParametricPathBase.typeKey,
        PathBase.typeKey,
        NodeBase.typeKey,
        TransformComponentBase.typeKey,
        ContainerComponentBase.typeKey,
        ComponentBase.typeKey
      };

  /// --------------------------------------------------------------------------
  /// Width field with key 20.
  double _width = 0;
  double _widthAnimated;
  KeyState _widthKeyState = KeyState.none;
  static const int widthPropertyKey = 20;

  /// Width of the parametric path.
  /// Get the [_width] field value.Note this may not match the core value if
  /// animation mode is active.
  double get width => _widthAnimated ?? _width;

  /// Get the non-animation [_width] field value.
  double get widthCore => _width;

  /// Change the [_width] field value.
  /// [widthChanged] will be invoked only if the field's value has changed.
  set widthCore(double value) {
    if (_width == value) {
      return;
    }
    double from = _width;
    _width = value;
    onPropertyChanged(widthPropertyKey, from, value);
    widthChanged(from, value);
  }

  set width(double value) {
    if (width == value) {
      return;
    }
    if (context != null && context.isAnimating) {
      _widthAnimate(value, true);
      return;
    }
    widthCore = value;
  }

  void _widthAnimate(double value, bool autoKey) {
    if (_widthAnimated == value) {
      return;
    }
    double from = width;
    _widthAnimated = value;
    double to = width;
    onAnimatedPropertyChanged(widthPropertyKey, autoKey, from, to);
    widthChanged(from, to);
  }

  double get widthAnimated => _widthAnimated;
  set widthAnimated(double value) => _widthAnimate(value, false);
  KeyState get widthKeyState => _widthKeyState;
  set widthKeyState(KeyState value) {
    if (_widthKeyState == value) {
      return;
    }
    _widthKeyState = value;
    // Force update anything listening on this property.
    onAnimatedPropertyChanged(
        widthPropertyKey, false, _widthAnimated, _widthAnimated);
  }

  void widthChanged(double from, double to);

  /// --------------------------------------------------------------------------
  /// Height field with key 21.
  double _height = 0;
  double _heightAnimated;
  KeyState _heightKeyState = KeyState.none;
  static const int heightPropertyKey = 21;

  /// Height of the parametric path.
  /// Get the [_height] field value.Note this may not match the core value if
  /// animation mode is active.
  double get height => _heightAnimated ?? _height;

  /// Get the non-animation [_height] field value.
  double get heightCore => _height;

  /// Change the [_height] field value.
  /// [heightChanged] will be invoked only if the field's value has changed.
  set heightCore(double value) {
    if (_height == value) {
      return;
    }
    double from = _height;
    _height = value;
    onPropertyChanged(heightPropertyKey, from, value);
    heightChanged(from, value);
  }

  set height(double value) {
    if (height == value) {
      return;
    }
    if (context != null && context.isAnimating) {
      _heightAnimate(value, true);
      return;
    }
    heightCore = value;
  }

  void _heightAnimate(double value, bool autoKey) {
    if (_heightAnimated == value) {
      return;
    }
    double from = height;
    _heightAnimated = value;
    double to = height;
    onAnimatedPropertyChanged(heightPropertyKey, autoKey, from, to);
    heightChanged(from, to);
  }

  double get heightAnimated => _heightAnimated;
  set heightAnimated(double value) => _heightAnimate(value, false);
  KeyState get heightKeyState => _heightKeyState;
  set heightKeyState(KeyState value) {
    if (_heightKeyState == value) {
      return;
    }
    _heightKeyState = value;
    // Force update anything listening on this property.
    onAnimatedPropertyChanged(
        heightPropertyKey, false, _heightAnimated, _heightAnimated);
  }

  void heightChanged(double from, double to);

  /// --------------------------------------------------------------------------
  /// OriginX field with key 123.
  double _originX = 0.5;
  double _originXAnimated;
  KeyState _originXKeyState = KeyState.none;
  static const int originXPropertyKey = 123;

  /// Origin x in normalized coordinates (0.5 = center, 0 = left, 1 = right).
  /// Get the [_originX] field value.Note this may not match the core value if
  /// animation mode is active.
  double get originX => _originXAnimated ?? _originX;

  /// Get the non-animation [_originX] field value.
  double get originXCore => _originX;

  /// Change the [_originX] field value.
  /// [originXChanged] will be invoked only if the field's value has changed.
  set originXCore(double value) {
    if (_originX == value) {
      return;
    }
    double from = _originX;
    _originX = value;
    onPropertyChanged(originXPropertyKey, from, value);
    originXChanged(from, value);
  }

  set originX(double value) {
    if (originX == value) {
      return;
    }
    if (context != null && context.isAnimating) {
      _originXAnimate(value, true);
      return;
    }
    originXCore = value;
  }

  void _originXAnimate(double value, bool autoKey) {
    if (_originXAnimated == value) {
      return;
    }
    double from = originX;
    _originXAnimated = value;
    double to = originX;
    onAnimatedPropertyChanged(originXPropertyKey, autoKey, from, to);
    originXChanged(from, to);
  }

  double get originXAnimated => _originXAnimated;
  set originXAnimated(double value) => _originXAnimate(value, false);
  KeyState get originXKeyState => _originXKeyState;
  set originXKeyState(KeyState value) {
    if (_originXKeyState == value) {
      return;
    }
    _originXKeyState = value;
    // Force update anything listening on this property.
    onAnimatedPropertyChanged(
        originXPropertyKey, false, _originXAnimated, _originXAnimated);
  }

  void originXChanged(double from, double to);

  /// --------------------------------------------------------------------------
  /// OriginY field with key 124.
  double _originY = 0.5;
  double _originYAnimated;
  KeyState _originYKeyState = KeyState.none;
  static const int originYPropertyKey = 124;

  /// Origin y in normalized coordinates (0.5 = center, 0 = top, 1 = bottom).
  /// Get the [_originY] field value.Note this may not match the core value if
  /// animation mode is active.
  double get originY => _originYAnimated ?? _originY;

  /// Get the non-animation [_originY] field value.
  double get originYCore => _originY;

  /// Change the [_originY] field value.
  /// [originYChanged] will be invoked only if the field's value has changed.
  set originYCore(double value) {
    if (_originY == value) {
      return;
    }
    double from = _originY;
    _originY = value;
    onPropertyChanged(originYPropertyKey, from, value);
    originYChanged(from, value);
  }

  set originY(double value) {
    if (originY == value) {
      return;
    }
    if (context != null && context.isAnimating) {
      _originYAnimate(value, true);
      return;
    }
    originYCore = value;
  }

  void _originYAnimate(double value, bool autoKey) {
    if (_originYAnimated == value) {
      return;
    }
    double from = originY;
    _originYAnimated = value;
    double to = originY;
    onAnimatedPropertyChanged(originYPropertyKey, autoKey, from, to);
    originYChanged(from, to);
  }

  double get originYAnimated => _originYAnimated;
  set originYAnimated(double value) => _originYAnimate(value, false);
  KeyState get originYKeyState => _originYKeyState;
  set originYKeyState(KeyState value) {
    if (_originYKeyState == value) {
      return;
    }
    _originYKeyState = value;
    // Force update anything listening on this property.
    onAnimatedPropertyChanged(
        originYPropertyKey, false, _originYAnimated, _originYAnimated);
  }

  void originYChanged(double from, double to);

  @override
  void changeNonNull() {
    super.changeNonNull();
    if (_width != null) {
      onPropertyChanged(widthPropertyKey, _width, _width);
    }
    if (_height != null) {
      onPropertyChanged(heightPropertyKey, _height, _height);
    }
    if (_originX != null) {
      onPropertyChanged(originXPropertyKey, _originX, _originX);
    }
    if (_originY != null) {
      onPropertyChanged(originYPropertyKey, _originY, _originY);
    }
  }

  @override
  void writeRuntimeProperties(BinaryWriter writer,
      HashMap<int, CoreFieldType> propertyToField, HashMap<Id, int> idLookup) {
    super.writeRuntimeProperties(writer, propertyToField, idLookup);
    if (_width != null && exports(widthPropertyKey)) {
      context.doubleType.writeRuntimeProperty(
          widthPropertyKey, writer, _width, propertyToField);
    }
    if (_height != null && exports(heightPropertyKey)) {
      context.doubleType.writeRuntimeProperty(
          heightPropertyKey, writer, _height, propertyToField);
    }
    if (_originX != null && exports(originXPropertyKey)) {
      context.doubleType.writeRuntimeProperty(
          originXPropertyKey, writer, _originX, propertyToField);
    }
    if (_originY != null && exports(originYPropertyKey)) {
      context.doubleType.writeRuntimeProperty(
          originYPropertyKey, writer, _originY, propertyToField);
    }
  }

  @override
  bool exports(int propertyKey) {
    switch (propertyKey) {
      case widthPropertyKey:
        return _width != 0;
      case heightPropertyKey:
        return _height != 0;
      case originXPropertyKey:
        return _originX != 0.5;
      case originYPropertyKey:
        return _originY != 0.5;
    }
    return super.exports(propertyKey);
  }

  @override
  K getProperty<K>(int propertyKey) {
    switch (propertyKey) {
      case widthPropertyKey:
        return width as K;
      case heightPropertyKey:
        return height as K;
      case originXPropertyKey:
        return originX as K;
      case originYPropertyKey:
        return originY as K;
      default:
        return super.getProperty<K>(propertyKey);
    }
  }

  @override
  bool hasProperty(int propertyKey) {
    switch (propertyKey) {
      case widthPropertyKey:
      case heightPropertyKey:
      case originXPropertyKey:
      case originYPropertyKey:
        return true;
      default:
        return super.hasProperty(propertyKey);
    }
  }
}
