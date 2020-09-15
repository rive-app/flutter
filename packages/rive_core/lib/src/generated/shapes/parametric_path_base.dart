/// Core automatically generated
/// lib/src/generated/shapes/parametric_path_base.dart.
/// Do not modify manually.

import 'dart:collection';
import 'package:core/core.dart';
import 'package:core/field_types/core_field_type.dart';
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
  static const int widthPropertyKey = 20;

  /// Width of the parametric path.
  double get width => _width;

  /// Change the [_width] field value.
  /// [widthChanged] will be invoked only if the field's value has changed.
  set width(double value) {
    if (_width == value) {
      return;
    }
    double from = _width;
    _width = value;
    onPropertyChanged(widthPropertyKey, from, value);
    widthChanged(from, value);
  }

  void widthChanged(double from, double to);

  /// --------------------------------------------------------------------------
  /// Height field with key 21.
  double _height = 0;
  static const int heightPropertyKey = 21;

  /// Height of the parametric path.
  double get height => _height;

  /// Change the [_height] field value.
  /// [heightChanged] will be invoked only if the field's value has changed.
  set height(double value) {
    if (_height == value) {
      return;
    }
    double from = _height;
    _height = value;
    onPropertyChanged(heightPropertyKey, from, value);
    heightChanged(from, value);
  }

  void heightChanged(double from, double to);

  @override
  void changeNonNull() {
    super.changeNonNull();
    if (_width != null) {
      onPropertyChanged(widthPropertyKey, _width, _width);
    }
    if (_height != null) {
      onPropertyChanged(heightPropertyKey, _height, _height);
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
  }

  @override
  bool exports(int propertyKey) {
    switch (propertyKey) {
      case widthPropertyKey:
        return _width != 0;
      case heightPropertyKey:
        return _height != 0;
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
      default:
        return super.getProperty<K>(propertyKey);
    }
  }

  @override
  bool hasProperty(int propertyKey) {
    switch (propertyKey) {
      case widthPropertyKey:
      case heightPropertyKey:
        return true;
      default:
        return super.hasProperty(propertyKey);
    }
  }
}
