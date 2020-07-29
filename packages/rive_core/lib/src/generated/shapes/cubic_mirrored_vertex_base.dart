/// Core automatically generated
/// lib/src/generated/shapes/cubic_mirrored_vertex_base.dart.
/// Do not modify manually.

import 'dart:collection';
import 'package:core/core.dart';
import 'package:core/key_state.dart';
import 'package:rive_core/shapes/cubic_vertex.dart';
import 'package:rive_core/src/generated/component_base.dart';
import 'package:rive_core/src/generated/shapes/cubic_vertex_base.dart';
import 'package:rive_core/src/generated/shapes/path_vertex_base.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

abstract class CubicMirroredVertexBase extends CubicVertex {
  static const int typeKey = 35;
  @override
  int get coreType => CubicMirroredVertexBase.typeKey;
  @override
  Set<int> get coreTypes => {
        CubicMirroredVertexBase.typeKey,
        CubicVertexBase.typeKey,
        PathVertexBase.typeKey,
        ComponentBase.typeKey
      };

  /// --------------------------------------------------------------------------
  /// Rotation field with key 82.
  double _rotation = 0;
  double _rotationAnimated;
  KeyState _rotationKeyState = KeyState.none;
  static const int rotationPropertyKey = 82;

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
  /// Distance field with key 83.
  double _distance = 0;
  double _distanceAnimated;
  KeyState _distanceKeyState = KeyState.none;
  static const int distancePropertyKey = 83;

  /// The control points' distance from the translation of the point.
  /// Get the [_distance] field value.Note this may not match the core value if
  /// animation mode is active.
  double get distance => _distanceAnimated ?? _distance;

  /// Get the non-animation [_distance] field value.
  double get distanceCore => _distance;

  /// Change the [_distance] field value.
  /// [distanceChanged] will be invoked only if the field's value has changed.
  set distanceCore(double value) {
    if (_distance == value) {
      return;
    }
    double from = _distance;
    _distance = value;
    onPropertyChanged(distancePropertyKey, from, value);
    distanceChanged(from, value);
  }

  set distance(double value) {
    if (distance == value) {
      return;
    }
    if (context != null && context.isAnimating) {
      _distanceAnimate(value, true);
      return;
    }
    distanceCore = value;
  }

  void _distanceAnimate(double value, bool autoKey) {
    if (_distanceAnimated == value) {
      return;
    }
    double from = distance;
    _distanceAnimated = value;
    double to = distance;
    onAnimatedPropertyChanged(distancePropertyKey, autoKey, from, to);
    distanceChanged(from, to);
  }

  double get distanceAnimated => _distanceAnimated;
  set distanceAnimated(double value) => _distanceAnimate(value, false);
  KeyState get distanceKeyState => _distanceKeyState;
  set distanceKeyState(KeyState value) {
    if (_distanceKeyState == value) {
      return;
    }
    _distanceKeyState = value;
    // Force update anything listening on this property.
    onAnimatedPropertyChanged(
        distancePropertyKey, false, _distanceAnimated, _distanceAnimated);
  }

  void distanceChanged(double from, double to);

  @override
  void changeNonNull() {
    super.changeNonNull();
    if (rotation != null) {
      onPropertyChanged(rotationPropertyKey, rotation, rotation);
    }
    if (distance != null) {
      onPropertyChanged(distancePropertyKey, distance, distance);
    }
  }

  @override
  void writeRuntimeProperties(BinaryWriter writer, HashMap<Id, int> idLookup) {
    super.writeRuntimeProperties(writer, idLookup);
    if (_rotation != null && exports(rotationPropertyKey)) {
      context.doubleType
          .writeRuntimeProperty(rotationPropertyKey, writer, _rotation);
    }
    if (_distance != null && exports(distancePropertyKey)) {
      context.doubleType
          .writeRuntimeProperty(distancePropertyKey, writer, _distance);
    }
  }

  @override
  bool exports(int propertyKey) {
    switch (propertyKey) {
      case rotationPropertyKey:
        return _rotation != 0;
      case distancePropertyKey:
        return _distance != 0;
    }
    return super.exports(propertyKey);
  }

  @override
  K getProperty<K>(int propertyKey) {
    switch (propertyKey) {
      case rotationPropertyKey:
        return rotation as K;
      case distancePropertyKey:
        return distance as K;
      default:
        return super.getProperty<K>(propertyKey);
    }
  }

  @override
  bool hasProperty(int propertyKey) {
    switch (propertyKey) {
      case rotationPropertyKey:
      case distancePropertyKey:
        return true;
      default:
        return super.hasProperty(propertyKey);
    }
  }
}
