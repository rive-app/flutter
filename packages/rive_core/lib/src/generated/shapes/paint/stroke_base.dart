/// Core automatically generated
/// lib/src/generated/shapes/paint/stroke_base.dart.
/// Do not modify manually.

import 'dart:collection';
import 'package:core/core.dart';
import 'package:core/field_types/core_field_type.dart';
import 'package:core/key_state.dart';
import 'package:rive_core/shapes/paint/shape_paint.dart';
import 'package:rive_core/src/generated/component_base.dart';
import 'package:rive_core/src/generated/container_component_base.dart';
import 'package:rive_core/src/generated/shapes/paint/shape_paint_base.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

abstract class StrokeBase extends ShapePaint {
  static const int typeKey = 24;
  @override
  int get coreType => StrokeBase.typeKey;
  @override
  Set<int> get coreTypes => {
        StrokeBase.typeKey,
        ShapePaintBase.typeKey,
        ContainerComponentBase.typeKey,
        ComponentBase.typeKey
      };

  /// --------------------------------------------------------------------------
  /// Thickness field with key 47.
  double _thickness = 1;
  double _thicknessAnimated;
  KeyState _thicknessKeyState = KeyState.none;
  static const int thicknessPropertyKey = 47;

  /// Get the [_thickness] field value.Note this may not match the core value if
  /// animation mode is active.
  double get thickness => _thicknessAnimated ?? _thickness;

  /// Get the non-animation [_thickness] field value.
  double get thicknessCore => _thickness;

  /// Change the [_thickness] field value.
  /// [thicknessChanged] will be invoked only if the field's value has changed.
  set thicknessCore(double value) {
    if (_thickness == value) {
      return;
    }
    double from = _thickness;
    _thickness = value;
    onPropertyChanged(thicknessPropertyKey, from, value);
    thicknessChanged(from, value);
  }

  set thickness(double value) {
    if (thickness == value) {
      return;
    }
    if (context != null && context.isAnimating) {
      _thicknessAnimate(value, true);
      return;
    }
    thicknessCore = value;
  }

  void _thicknessAnimate(double value, bool autoKey) {
    if (_thicknessAnimated == value) {
      return;
    }
    double from = thickness;
    _thicknessAnimated = value;
    double to = thickness;
    onAnimatedPropertyChanged(thicknessPropertyKey, autoKey, from, to);
    thicknessChanged(from, to);
  }

  double get thicknessAnimated => _thicknessAnimated;
  set thicknessAnimated(double value) => _thicknessAnimate(value, false);
  KeyState get thicknessKeyState => _thicknessKeyState;
  set thicknessKeyState(KeyState value) {
    if (_thicknessKeyState == value) {
      return;
    }
    _thicknessKeyState = value;
    // Force update anything listening on this property.
    onAnimatedPropertyChanged(
        thicknessPropertyKey, false, _thicknessAnimated, _thicknessAnimated);
  }

  void thicknessChanged(double from, double to);

  /// --------------------------------------------------------------------------
  /// Cap field with key 48.
  int _cap = 0;
  static const int capPropertyKey = 48;
  int get cap => _cap;

  /// Change the [_cap] field value.
  /// [capChanged] will be invoked only if the field's value has changed.
  set cap(int value) {
    if (_cap == value) {
      return;
    }
    int from = _cap;
    _cap = value;
    onPropertyChanged(capPropertyKey, from, value);
    capChanged(from, value);
  }

  void capChanged(int from, int to);

  /// --------------------------------------------------------------------------
  /// Join field with key 49.
  int _join = 0;
  static const int joinPropertyKey = 49;
  int get join => _join;

  /// Change the [_join] field value.
  /// [joinChanged] will be invoked only if the field's value has changed.
  set join(int value) {
    if (_join == value) {
      return;
    }
    int from = _join;
    _join = value;
    onPropertyChanged(joinPropertyKey, from, value);
    joinChanged(from, value);
  }

  void joinChanged(int from, int to);

  /// --------------------------------------------------------------------------
  /// TransformAffectsStroke field with key 50.
  bool _transformAffectsStroke = true;
  static const int transformAffectsStrokePropertyKey = 50;
  bool get transformAffectsStroke => _transformAffectsStroke;

  /// Change the [_transformAffectsStroke] field value.
  /// [transformAffectsStrokeChanged] will be invoked only if the field's value
  /// has changed.
  set transformAffectsStroke(bool value) {
    if (_transformAffectsStroke == value) {
      return;
    }
    bool from = _transformAffectsStroke;
    _transformAffectsStroke = value;
    onPropertyChanged(transformAffectsStrokePropertyKey, from, value);
    transformAffectsStrokeChanged(from, value);
  }

  void transformAffectsStrokeChanged(bool from, bool to);

  @override
  void changeNonNull() {
    super.changeNonNull();
    if (_thickness != null) {
      onPropertyChanged(thicknessPropertyKey, _thickness, _thickness);
    }
    if (_cap != null) {
      onPropertyChanged(capPropertyKey, _cap, _cap);
    }
    if (_join != null) {
      onPropertyChanged(joinPropertyKey, _join, _join);
    }
    if (_transformAffectsStroke != null) {
      onPropertyChanged(transformAffectsStrokePropertyKey,
          _transformAffectsStroke, _transformAffectsStroke);
    }
  }

  @override
  void writeRuntimeProperties(BinaryWriter writer,
      HashMap<int, CoreFieldType> propertyToField, HashMap<Id, int> idLookup) {
    super.writeRuntimeProperties(writer, propertyToField, idLookup);
    if (_thickness != null && exports(thicknessPropertyKey)) {
      context.doubleType.writeRuntimeProperty(
          thicknessPropertyKey, writer, _thickness, propertyToField);
    }
    if (_cap != null && exports(capPropertyKey)) {
      context.uintType
          .writeRuntimeProperty(capPropertyKey, writer, _cap, propertyToField);
    }
    if (_join != null && exports(joinPropertyKey)) {
      context.uintType.writeRuntimeProperty(
          joinPropertyKey, writer, _join, propertyToField);
    }
    if (_transformAffectsStroke != null &&
        exports(transformAffectsStrokePropertyKey)) {
      context.boolType.writeRuntimeProperty(transformAffectsStrokePropertyKey,
          writer, _transformAffectsStroke, propertyToField);
    }
  }

  @override
  bool exports(int propertyKey) {
    switch (propertyKey) {
      case thicknessPropertyKey:
        return _thickness != 1;
      case capPropertyKey:
        return _cap != 0;
      case joinPropertyKey:
        return _join != 0;
      case transformAffectsStrokePropertyKey:
        return _transformAffectsStroke != true;
    }
    return super.exports(propertyKey);
  }

  @override
  K getProperty<K>(int propertyKey) {
    switch (propertyKey) {
      case thicknessPropertyKey:
        return thickness as K;
      case capPropertyKey:
        return cap as K;
      case joinPropertyKey:
        return join as K;
      case transformAffectsStrokePropertyKey:
        return transformAffectsStroke as K;
      default:
        return super.getProperty<K>(propertyKey);
    }
  }

  @override
  bool hasProperty(int propertyKey) {
    switch (propertyKey) {
      case thicknessPropertyKey:
      case capPropertyKey:
      case joinPropertyKey:
      case transformAffectsStrokePropertyKey:
        return true;
      default:
        return super.hasProperty(propertyKey);
    }
  }
}
