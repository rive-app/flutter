/// Core automatically generated
/// lib/src/generated/shapes/cubic_asymmetric_vertex_base.dart.
/// Do not modify manually.

import 'dart:collection';
import 'package:core/core.dart';
import 'package:core/key_state.dart';
import 'package:rive_core/shapes/cubic_vertex.dart';
import 'package:rive_core/src/generated/component_base.dart';
import 'package:rive_core/src/generated/shapes/cubic_vertex_base.dart';
import 'package:rive_core/src/generated/shapes/path_vertex_base.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

abstract class CubicAsymmetricVertexBase extends CubicVertex {
  static const int typeKey = 34;
  @override
  int get coreType => CubicAsymmetricVertexBase.typeKey;
  @override
  Set<int> get coreTypes => {
        CubicAsymmetricVertexBase.typeKey,
        CubicVertexBase.typeKey,
        PathVertexBase.typeKey,
        ComponentBase.typeKey
      };

  /// --------------------------------------------------------------------------
  /// Rotation field with key 79.
  double _rotation = 0;
  double _rotationAnimated;
  KeyState _rotationKeyState = KeyState.none;
  static const int rotationPropertyKey = 79;

  /// The control points' angle.
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
    if (rotation == value) {
      return;
    }
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
  /// InDistance field with key 80.
  double _inDistance = 0;
  double _inDistanceAnimated;
  KeyState _inDistanceKeyState = KeyState.none;
  static const int inDistancePropertyKey = 80;

  /// The in point's distance from the translation of the point.
  /// Get the [_inDistance] field value.Note this may not match the core value
  /// if animation mode is active.
  double get inDistance => _inDistanceAnimated ?? _inDistance;

  /// Get the non-animation [_inDistance] field value.
  double get inDistanceCore => _inDistance;

  /// Change the [_inDistance] field value.
  /// [inDistanceChanged] will be invoked only if the field's value has changed.
  set inDistanceCore(double value) {
    if (_inDistance == value) {
      return;
    }
    double from = _inDistance;
    _inDistance = value;
    onPropertyChanged(inDistancePropertyKey, from, value);
    inDistanceChanged(from, value);
  }

  set inDistance(double value) {
    if (inDistance == value) {
      return;
    }
    if (context != null && context.isAnimating) {
      _inDistanceAnimate(value, true);
      return;
    }
    inDistanceCore = value;
  }

  void _inDistanceAnimate(double value, bool autoKey) {
    if (_inDistanceAnimated == value) {
      return;
    }
    double from = inDistance;
    _inDistanceAnimated = value;
    double to = inDistance;
    onAnimatedPropertyChanged(inDistancePropertyKey, autoKey, from, to);
    inDistanceChanged(from, to);
  }

  double get inDistanceAnimated => _inDistanceAnimated;
  set inDistanceAnimated(double value) => _inDistanceAnimate(value, false);
  KeyState get inDistanceKeyState => _inDistanceKeyState;
  set inDistanceKeyState(KeyState value) {
    if (_inDistanceKeyState == value) {
      return;
    }
    _inDistanceKeyState = value;
    // Force update anything listening on this property.
    onAnimatedPropertyChanged(
        inDistancePropertyKey, false, _inDistanceAnimated, _inDistanceAnimated);
  }

  void inDistanceChanged(double from, double to);

  /// --------------------------------------------------------------------------
  /// OutDistance field with key 81.
  double _outDistance = 0;
  double _outDistanceAnimated;
  KeyState _outDistanceKeyState = KeyState.none;
  static const int outDistancePropertyKey = 81;

  /// The out point's distance from the translation of the point.
  /// Get the [_outDistance] field value.Note this may not match the core value
  /// if animation mode is active.
  double get outDistance => _outDistanceAnimated ?? _outDistance;

  /// Get the non-animation [_outDistance] field value.
  double get outDistanceCore => _outDistance;

  /// Change the [_outDistance] field value.
  /// [outDistanceChanged] will be invoked only if the field's value has
  /// changed.
  set outDistanceCore(double value) {
    if (_outDistance == value) {
      return;
    }
    double from = _outDistance;
    _outDistance = value;
    onPropertyChanged(outDistancePropertyKey, from, value);
    outDistanceChanged(from, value);
  }

  set outDistance(double value) {
    if (outDistance == value) {
      return;
    }
    if (context != null && context.isAnimating) {
      _outDistanceAnimate(value, true);
      return;
    }
    outDistanceCore = value;
  }

  void _outDistanceAnimate(double value, bool autoKey) {
    if (_outDistanceAnimated == value) {
      return;
    }
    double from = outDistance;
    _outDistanceAnimated = value;
    double to = outDistance;
    onAnimatedPropertyChanged(outDistancePropertyKey, autoKey, from, to);
    outDistanceChanged(from, to);
  }

  double get outDistanceAnimated => _outDistanceAnimated;
  set outDistanceAnimated(double value) => _outDistanceAnimate(value, false);
  KeyState get outDistanceKeyState => _outDistanceKeyState;
  set outDistanceKeyState(KeyState value) {
    if (_outDistanceKeyState == value) {
      return;
    }
    _outDistanceKeyState = value;
    // Force update anything listening on this property.
    onAnimatedPropertyChanged(outDistancePropertyKey, false,
        _outDistanceAnimated, _outDistanceAnimated);
  }

  void outDistanceChanged(double from, double to);

  @override
  void changeNonNull() {
    super.changeNonNull();
    if (rotation != null) {
      onPropertyChanged(rotationPropertyKey, rotation, rotation);
    }
    if (inDistance != null) {
      onPropertyChanged(inDistancePropertyKey, inDistance, inDistance);
    }
    if (outDistance != null) {
      onPropertyChanged(outDistancePropertyKey, outDistance, outDistance);
    }
  }

  @override
  void writeRuntimeProperties(BinaryWriter writer, HashMap<Id, int> idLookup) {
    super.writeRuntimeProperties(writer, idLookup);
    if (_rotation != null && exports(rotationPropertyKey)) {
      context.doubleType
          .writeRuntimeProperty(rotationPropertyKey, writer, _rotation);
    }
    if (_inDistance != null && exports(inDistancePropertyKey)) {
      context.doubleType
          .writeRuntimeProperty(inDistancePropertyKey, writer, _inDistance);
    }
    if (_outDistance != null && exports(outDistancePropertyKey)) {
      context.doubleType
          .writeRuntimeProperty(outDistancePropertyKey, writer, _outDistance);
    }
  }

  @override
  bool exports(int propertyKey) {
    switch (propertyKey) {
      case rotationPropertyKey:
        return _rotation != 0;
      case inDistancePropertyKey:
        return _inDistance != 0;
      case outDistancePropertyKey:
        return _outDistance != 0;
    }
    return super.exports(propertyKey);
  }

  @override
  K getProperty<K>(int propertyKey) {
    switch (propertyKey) {
      case rotationPropertyKey:
        return rotation as K;
      case inDistancePropertyKey:
        return inDistance as K;
      case outDistancePropertyKey:
        return outDistance as K;
      default:
        return super.getProperty<K>(propertyKey);
    }
  }

  @override
  bool hasProperty(int propertyKey) {
    switch (propertyKey) {
      case rotationPropertyKey:
      case inDistancePropertyKey:
      case outDistancePropertyKey:
        return true;
      default:
        return super.hasProperty(propertyKey);
    }
  }
}
