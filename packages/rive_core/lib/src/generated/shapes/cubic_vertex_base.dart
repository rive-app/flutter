/// Core automatically generated
/// lib/src/generated/shapes/cubic_vertex_base.dart.
/// Do not modify manually.

import 'dart:collection';
import 'package:core/core.dart';
import 'package:core/key_state.dart';
import 'package:rive_core/shapes/path_vertex.dart';
import 'package:rive_core/src/generated/component_base.dart';
import 'package:rive_core/src/generated/shapes/path_vertex_base.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

abstract class CubicVertexBase extends PathVertex {
  static const int typeKey = 6;
  @override
  int get coreType => CubicVertexBase.typeKey;
  @override
  Set<int> get coreTypes =>
      {CubicVertexBase.typeKey, PathVertexBase.typeKey, ComponentBase.typeKey};

  /// --------------------------------------------------------------------------
  /// ControlTypeValue field with key 75.
  int _controlTypeValue = 1;
  static const int controlTypeValuePropertyKey = 75;

  /// Backing integer value for the CubicControlType enum that describes how the
  /// handles move in relation to each other.
  int get controlTypeValue => _controlTypeValue;

  /// Change the [_controlTypeValue] field value.
  /// [controlTypeValueChanged] will be invoked only if the field's value has
  /// changed.
  set controlTypeValue(int value) {
    if (_controlTypeValue == value) {
      return;
    }
    int from = _controlTypeValue;
    _controlTypeValue = value;
    onPropertyChanged(controlTypeValuePropertyKey, from, value);
    controlTypeValueChanged(from, value);
  }

  void controlTypeValueChanged(int from, int to);

  /// --------------------------------------------------------------------------
  /// InX field with key 27.
  double _inX = 0;
  double _inXAnimated;
  KeyState _inXKeyState = KeyState.none;
  static const int inXPropertyKey = 27;

  /// In point's x value
  /// Get the [_inX] field value.Note this may not match the core value if
  /// animation mode is active.
  double get inX => _inXAnimated ?? _inX;

  /// Get the non-animation [_inX] field value.
  double get inXCore => _inX;

  /// Change the [_inX] field value.
  /// [inXChanged] will be invoked only if the field's value has changed.
  set inXCore(double value) {
    if (_inX == value) {
      return;
    }
    double from = _inX;
    _inX = value;
    onPropertyChanged(inXPropertyKey, from, value);
    inXChanged(from, value);
  }

  set inX(double value) {
    if (context != null && context.isAnimating) {
      _inXAnimate(value, true);
      return;
    }
    inXCore = value;
  }

  void _inXAnimate(double value, bool autoKey) {
    if (_inXAnimated == value) {
      return;
    }
    double from = inX;
    _inXAnimated = value;
    double to = inX;
    onAnimatedPropertyChanged(inXPropertyKey, autoKey, from, to);
    inXChanged(from, to);
  }

  double get inXAnimated => _inXAnimated;
  set inXAnimated(double value) => _inXAnimate(value, false);
  KeyState get inXKeyState => _inXKeyState;
  set inXKeyState(KeyState value) {
    if (_inXKeyState == value) {
      return;
    }
    _inXKeyState = value;
    // Force update anything listening on this property.
    onAnimatedPropertyChanged(
        inXPropertyKey, false, _inXAnimated, _inXAnimated);
  }

  void inXChanged(double from, double to);

  /// --------------------------------------------------------------------------
  /// InY field with key 28.
  double _inY = 0;
  double _inYAnimated;
  KeyState _inYKeyState = KeyState.none;
  static const int inYPropertyKey = 28;

  /// In point's y value
  /// Get the [_inY] field value.Note this may not match the core value if
  /// animation mode is active.
  double get inY => _inYAnimated ?? _inY;

  /// Get the non-animation [_inY] field value.
  double get inYCore => _inY;

  /// Change the [_inY] field value.
  /// [inYChanged] will be invoked only if the field's value has changed.
  set inYCore(double value) {
    if (_inY == value) {
      return;
    }
    double from = _inY;
    _inY = value;
    onPropertyChanged(inYPropertyKey, from, value);
    inYChanged(from, value);
  }

  set inY(double value) {
    if (context != null && context.isAnimating) {
      _inYAnimate(value, true);
      return;
    }
    inYCore = value;
  }

  void _inYAnimate(double value, bool autoKey) {
    if (_inYAnimated == value) {
      return;
    }
    double from = inY;
    _inYAnimated = value;
    double to = inY;
    onAnimatedPropertyChanged(inYPropertyKey, autoKey, from, to);
    inYChanged(from, to);
  }

  double get inYAnimated => _inYAnimated;
  set inYAnimated(double value) => _inYAnimate(value, false);
  KeyState get inYKeyState => _inYKeyState;
  set inYKeyState(KeyState value) {
    if (_inYKeyState == value) {
      return;
    }
    _inYKeyState = value;
    // Force update anything listening on this property.
    onAnimatedPropertyChanged(
        inYPropertyKey, false, _inYAnimated, _inYAnimated);
  }

  void inYChanged(double from, double to);

  /// --------------------------------------------------------------------------
  /// OutX field with key 29.
  double _outX = 0;
  double _outXAnimated;
  KeyState _outXKeyState = KeyState.none;
  static const int outXPropertyKey = 29;

  /// Out point's x value
  /// Get the [_outX] field value.Note this may not match the core value if
  /// animation mode is active.
  double get outX => _outXAnimated ?? _outX;

  /// Get the non-animation [_outX] field value.
  double get outXCore => _outX;

  /// Change the [_outX] field value.
  /// [outXChanged] will be invoked only if the field's value has changed.
  set outXCore(double value) {
    if (_outX == value) {
      return;
    }
    double from = _outX;
    _outX = value;
    onPropertyChanged(outXPropertyKey, from, value);
    outXChanged(from, value);
  }

  set outX(double value) {
    if (context != null && context.isAnimating) {
      _outXAnimate(value, true);
      return;
    }
    outXCore = value;
  }

  void _outXAnimate(double value, bool autoKey) {
    if (_outXAnimated == value) {
      return;
    }
    double from = outX;
    _outXAnimated = value;
    double to = outX;
    onAnimatedPropertyChanged(outXPropertyKey, autoKey, from, to);
    outXChanged(from, to);
  }

  double get outXAnimated => _outXAnimated;
  set outXAnimated(double value) => _outXAnimate(value, false);
  KeyState get outXKeyState => _outXKeyState;
  set outXKeyState(KeyState value) {
    if (_outXKeyState == value) {
      return;
    }
    _outXKeyState = value;
    // Force update anything listening on this property.
    onAnimatedPropertyChanged(
        outXPropertyKey, false, _outXAnimated, _outXAnimated);
  }

  void outXChanged(double from, double to);

  /// --------------------------------------------------------------------------
  /// OutY field with key 30.
  double _outY = 0;
  double _outYAnimated;
  KeyState _outYKeyState = KeyState.none;
  static const int outYPropertyKey = 30;

  /// Out point's y value
  /// Get the [_outY] field value.Note this may not match the core value if
  /// animation mode is active.
  double get outY => _outYAnimated ?? _outY;

  /// Get the non-animation [_outY] field value.
  double get outYCore => _outY;

  /// Change the [_outY] field value.
  /// [outYChanged] will be invoked only if the field's value has changed.
  set outYCore(double value) {
    if (_outY == value) {
      return;
    }
    double from = _outY;
    _outY = value;
    onPropertyChanged(outYPropertyKey, from, value);
    outYChanged(from, value);
  }

  set outY(double value) {
    if (context != null && context.isAnimating) {
      _outYAnimate(value, true);
      return;
    }
    outYCore = value;
  }

  void _outYAnimate(double value, bool autoKey) {
    if (_outYAnimated == value) {
      return;
    }
    double from = outY;
    _outYAnimated = value;
    double to = outY;
    onAnimatedPropertyChanged(outYPropertyKey, autoKey, from, to);
    outYChanged(from, to);
  }

  double get outYAnimated => _outYAnimated;
  set outYAnimated(double value) => _outYAnimate(value, false);
  KeyState get outYKeyState => _outYKeyState;
  set outYKeyState(KeyState value) {
    if (_outYKeyState == value) {
      return;
    }
    _outYKeyState = value;
    // Force update anything listening on this property.
    onAnimatedPropertyChanged(
        outYPropertyKey, false, _outYAnimated, _outYAnimated);
  }

  void outYChanged(double from, double to);

  @override
  void changeNonNull() {
    super.changeNonNull();
    if (controlTypeValue != null) {
      onPropertyChanged(
          controlTypeValuePropertyKey, controlTypeValue, controlTypeValue);
    }
    if (inX != null) {
      onPropertyChanged(inXPropertyKey, inX, inX);
    }
    if (inY != null) {
      onPropertyChanged(inYPropertyKey, inY, inY);
    }
    if (outX != null) {
      onPropertyChanged(outXPropertyKey, outX, outX);
    }
    if (outY != null) {
      onPropertyChanged(outYPropertyKey, outY, outY);
    }
  }

  @override
  void writeRuntimeProperties(BinaryWriter writer, HashMap<Id, int> idLookup) {
    super.writeRuntimeProperties(writer, idLookup);
    if (_controlTypeValue != null) {
      context.intType.writeProperty(
          controlTypeValuePropertyKey, writer, _controlTypeValue);
    }
    if (_inX != null) {
      context.doubleType.writeProperty(inXPropertyKey, writer, _inX);
    }
    if (_inY != null) {
      context.doubleType.writeProperty(inYPropertyKey, writer, _inY);
    }
    if (_outX != null) {
      context.doubleType.writeProperty(outXPropertyKey, writer, _outX);
    }
    if (_outY != null) {
      context.doubleType.writeProperty(outYPropertyKey, writer, _outY);
    }
  }

  @override
  K getProperty<K>(int propertyKey) {
    switch (propertyKey) {
      case controlTypeValuePropertyKey:
        return controlTypeValue as K;
      case inXPropertyKey:
        return inX as K;
      case inYPropertyKey:
        return inY as K;
      case outXPropertyKey:
        return outX as K;
      case outYPropertyKey:
        return outY as K;
      default:
        return super.getProperty<K>(propertyKey);
    }
  }

  @override
  bool hasProperty(int propertyKey) {
    switch (propertyKey) {
      case controlTypeValuePropertyKey:
      case inXPropertyKey:
      case inYPropertyKey:
      case outXPropertyKey:
      case outYPropertyKey:
        return true;
      default:
        return super.hasProperty(propertyKey);
    }
  }
}
