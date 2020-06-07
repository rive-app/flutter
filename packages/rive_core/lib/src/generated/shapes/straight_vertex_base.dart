/// Core automatically generated
/// lib/src/generated/shapes/straight_vertex_base.dart.
/// Do not modify manually.

import 'dart:collection';
import 'package:core/core.dart';
import 'package:core/key_state.dart';
import 'package:rive_core/shapes/path_vertex.dart';
import 'package:rive_core/src/generated/component_base.dart';
import 'package:rive_core/src/generated/shapes/path_vertex_base.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

abstract class StraightVertexBase extends PathVertex {
  static const int typeKey = 5;
  @override
  int get coreType => StraightVertexBase.typeKey;
  @override
  Set<int> get coreTypes => {
        StraightVertexBase.typeKey,
        PathVertexBase.typeKey,
        ComponentBase.typeKey
      };

  /// --------------------------------------------------------------------------
  /// Radius field with key 26.
  double _radius;
  double _radiusAnimated;
  KeyState _radiusKeyState = KeyState.none;
  static const int radiusPropertyKey = 26;

  /// Radius of the vertex
  /// Get the [_radius] field value.Note this may not match the core value if
  /// animation mode is active.
  double get radius => _radiusAnimated ?? _radius;

  /// Get the non-animation [_radius] field value.
  double get radiusCore => _radius;

  /// Change the [_radius] field value.
  /// [radiusChanged] will be invoked only if the field's value has changed.
  set radiusCore(double value) {
    if (_radius == value) {
      return;
    }
    double from = _radius;
    _radius = value;
    onPropertyChanged(radiusPropertyKey, from, value);
    radiusChanged(from, value);
  }

  set radius(double value) {
    if (context != null && context.isAnimating) {
      _radiusAnimate(value, true);
      return;
    }
    radiusCore = value;
  }

  void _radiusAnimate(double value, bool autoKey) {
    if (_radiusAnimated == value) {
      return;
    }
    double from = radius;
    _radiusAnimated = value;
    double to = radius;
    onAnimatedPropertyChanged(radiusPropertyKey, autoKey, from, to);
    radiusChanged(from, to);
  }

  double get radiusAnimated => _radiusAnimated;
  set radiusAnimated(double value) => _radiusAnimate(value, false);
  KeyState get radiusKeyState => _radiusKeyState;
  set radiusKeyState(KeyState value) {
    if (_radiusKeyState == value) {
      return;
    }
    _radiusKeyState = value;
    // Force update anything listening on this property.
    onAnimatedPropertyChanged(
        radiusPropertyKey, false, _radiusAnimated, _radiusAnimated);
  }

  void radiusChanged(double from, double to);

  @override
  void changeNonNull() {
    super.changeNonNull();
    if (radius != null) {
      onPropertyChanged(radiusPropertyKey, radius, radius);
    }
  }

  @override
  void writeRuntimeProperties(BinaryWriter writer, HashMap<Id, int> idLookup) {
    super.writeRuntimeProperties(writer, idLookup);
    if (_radius != null) {
      context.doubleType.writeProperty(radiusPropertyKey, writer, _radius);
    }
  }

  @override
  K getProperty<K>(int propertyKey) {
    switch (propertyKey) {
      case radiusPropertyKey:
        return radius as K;
      default:
        return super.getProperty<K>(propertyKey);
    }
  }

  @override
  bool hasProperty(int propertyKey) {
    switch (propertyKey) {
      case radiusPropertyKey:
        return true;
      default:
        return super.hasProperty(propertyKey);
    }
  }
}
