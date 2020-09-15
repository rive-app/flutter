/// Core automatically generated
/// lib/src/generated/shapes/cubic_detached_vertex_base.dart.
/// Do not modify manually.

import 'dart:collection';
import 'package:core/core.dart';
import 'package:core/field_types/core_field_type.dart';
import 'package:core/key_state.dart';
import 'package:rive_core/shapes/cubic_vertex.dart';
import 'package:rive_core/src/generated/component_base.dart';
import 'package:rive_core/src/generated/container_component_base.dart';
import 'package:rive_core/src/generated/shapes/cubic_vertex_base.dart';
import 'package:rive_core/src/generated/shapes/path_vertex_base.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

abstract class CubicDetachedVertexBase extends CubicVertex {
  static const int typeKey = 6;
  @override
  int get coreType => CubicDetachedVertexBase.typeKey;
  @override
  Set<int> get coreTypes => {
        CubicDetachedVertexBase.typeKey,
        CubicVertexBase.typeKey,
        PathVertexBase.typeKey,
        ContainerComponentBase.typeKey,
        ComponentBase.typeKey
      };

  /// --------------------------------------------------------------------------
  /// InRotation field with key 84.
  double _inRotation = 0;
  double _inRotationAnimated;
  KeyState _inRotationKeyState = KeyState.none;
  static const int inRotationPropertyKey = 84;

  /// The in point's angle.
  /// Get the [_inRotation] field value.Note this may not match the core value
  /// if animation mode is active.
  double get inRotation => _inRotationAnimated ?? _inRotation;

  /// Get the non-animation [_inRotation] field value.
  double get inRotationCore => _inRotation;

  /// Change the [_inRotation] field value.
  /// [inRotationChanged] will be invoked only if the field's value has changed.
  set inRotationCore(double value) {
    if (_inRotation == value) {
      return;
    }
    double from = _inRotation;
    _inRotation = value;
    onPropertyChanged(inRotationPropertyKey, from, value);
    inRotationChanged(from, value);
  }

  set inRotation(double value) {
    if (inRotation == value) {
      return;
    }
    if (context != null && context.isAnimating) {
      _inRotationAnimate(value, true);
      return;
    }
    inRotationCore = value;
  }

  void _inRotationAnimate(double value, bool autoKey) {
    if (_inRotationAnimated == value) {
      return;
    }
    double from = inRotation;
    _inRotationAnimated = value;
    double to = inRotation;
    onAnimatedPropertyChanged(inRotationPropertyKey, autoKey, from, to);
    inRotationChanged(from, to);
  }

  double get inRotationAnimated => _inRotationAnimated;
  set inRotationAnimated(double value) => _inRotationAnimate(value, false);
  KeyState get inRotationKeyState => _inRotationKeyState;
  set inRotationKeyState(KeyState value) {
    if (_inRotationKeyState == value) {
      return;
    }
    _inRotationKeyState = value;
    // Force update anything listening on this property.
    onAnimatedPropertyChanged(
        inRotationPropertyKey, false, _inRotationAnimated, _inRotationAnimated);
  }

  void inRotationChanged(double from, double to);

  /// --------------------------------------------------------------------------
  /// InDistance field with key 85.
  double _inDistance = 0;
  double _inDistanceAnimated;
  KeyState _inDistanceKeyState = KeyState.none;
  static const int inDistancePropertyKey = 85;

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
  /// OutRotation field with key 86.
  double _outRotation = 0;
  double _outRotationAnimated;
  KeyState _outRotationKeyState = KeyState.none;
  static const int outRotationPropertyKey = 86;

  /// The out point's angle.
  /// Get the [_outRotation] field value.Note this may not match the core value
  /// if animation mode is active.
  double get outRotation => _outRotationAnimated ?? _outRotation;

  /// Get the non-animation [_outRotation] field value.
  double get outRotationCore => _outRotation;

  /// Change the [_outRotation] field value.
  /// [outRotationChanged] will be invoked only if the field's value has
  /// changed.
  set outRotationCore(double value) {
    if (_outRotation == value) {
      return;
    }
    double from = _outRotation;
    _outRotation = value;
    onPropertyChanged(outRotationPropertyKey, from, value);
    outRotationChanged(from, value);
  }

  set outRotation(double value) {
    if (outRotation == value) {
      return;
    }
    if (context != null && context.isAnimating) {
      _outRotationAnimate(value, true);
      return;
    }
    outRotationCore = value;
  }

  void _outRotationAnimate(double value, bool autoKey) {
    if (_outRotationAnimated == value) {
      return;
    }
    double from = outRotation;
    _outRotationAnimated = value;
    double to = outRotation;
    onAnimatedPropertyChanged(outRotationPropertyKey, autoKey, from, to);
    outRotationChanged(from, to);
  }

  double get outRotationAnimated => _outRotationAnimated;
  set outRotationAnimated(double value) => _outRotationAnimate(value, false);
  KeyState get outRotationKeyState => _outRotationKeyState;
  set outRotationKeyState(KeyState value) {
    if (_outRotationKeyState == value) {
      return;
    }
    _outRotationKeyState = value;
    // Force update anything listening on this property.
    onAnimatedPropertyChanged(outRotationPropertyKey, false,
        _outRotationAnimated, _outRotationAnimated);
  }

  void outRotationChanged(double from, double to);

  /// --------------------------------------------------------------------------
  /// OutDistance field with key 87.
  double _outDistance = 0;
  double _outDistanceAnimated;
  KeyState _outDistanceKeyState = KeyState.none;
  static const int outDistancePropertyKey = 87;

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
    if (_inRotation != null) {
      onPropertyChanged(inRotationPropertyKey, _inRotation, _inRotation);
    }
    if (_inDistance != null) {
      onPropertyChanged(inDistancePropertyKey, _inDistance, _inDistance);
    }
    if (_outRotation != null) {
      onPropertyChanged(outRotationPropertyKey, _outRotation, _outRotation);
    }
    if (_outDistance != null) {
      onPropertyChanged(outDistancePropertyKey, _outDistance, _outDistance);
    }
  }

  @override
  void writeRuntimeProperties(BinaryWriter writer,
      HashMap<int, CoreFieldType> propertyToField, HashMap<Id, int> idLookup) {
    super.writeRuntimeProperties(writer, propertyToField, idLookup);
    if (_inRotation != null && exports(inRotationPropertyKey)) {
      context.doubleType.writeRuntimeProperty(
          inRotationPropertyKey, writer, _inRotation, propertyToField);
    }
    if (_inDistance != null && exports(inDistancePropertyKey)) {
      context.doubleType.writeRuntimeProperty(
          inDistancePropertyKey, writer, _inDistance, propertyToField);
    }
    if (_outRotation != null && exports(outRotationPropertyKey)) {
      context.doubleType.writeRuntimeProperty(
          outRotationPropertyKey, writer, _outRotation, propertyToField);
    }
    if (_outDistance != null && exports(outDistancePropertyKey)) {
      context.doubleType.writeRuntimeProperty(
          outDistancePropertyKey, writer, _outDistance, propertyToField);
    }
  }

  @override
  bool exports(int propertyKey) {
    switch (propertyKey) {
      case inRotationPropertyKey:
        return _inRotation != 0;
      case inDistancePropertyKey:
        return _inDistance != 0;
      case outRotationPropertyKey:
        return _outRotation != 0;
      case outDistancePropertyKey:
        return _outDistance != 0;
    }
    return super.exports(propertyKey);
  }

  @override
  K getProperty<K>(int propertyKey) {
    switch (propertyKey) {
      case inRotationPropertyKey:
        return inRotation as K;
      case inDistancePropertyKey:
        return inDistance as K;
      case outRotationPropertyKey:
        return outRotation as K;
      case outDistancePropertyKey:
        return outDistance as K;
      default:
        return super.getProperty<K>(propertyKey);
    }
  }

  @override
  bool hasProperty(int propertyKey) {
    switch (propertyKey) {
      case inRotationPropertyKey:
      case inDistancePropertyKey:
      case outRotationPropertyKey:
      case outDistancePropertyKey:
        return true;
      default:
        return super.hasProperty(propertyKey);
    }
  }
}
