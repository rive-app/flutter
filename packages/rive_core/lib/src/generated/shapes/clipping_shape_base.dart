/// Core automatically generated
/// lib/src/generated/shapes/clipping_shape_base.dart.
/// Do not modify manually.

import 'dart:collection';
import 'package:core/core.dart';
import 'package:core/field_types/core_field_type.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/src/generated/component_base.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

abstract class ClippingShapeBase extends Component {
  static const int typeKey = 42;
  @override
  int get coreType => ClippingShapeBase.typeKey;
  @override
  Set<int> get coreTypes => {ClippingShapeBase.typeKey, ComponentBase.typeKey};

  /// --------------------------------------------------------------------------
  /// ShapeId field with key 92.
  Id _shapeId;
  static const int shapeIdPropertyKey = 92;

  /// Identifier used to track the shape to use as a clipping source.
  Id get shapeId => _shapeId;

  /// Change the [_shapeId] field value.
  /// [shapeIdChanged] will be invoked only if the field's value has changed.
  set shapeId(Id value) {
    if (_shapeId == value) {
      return;
    }
    Id from = _shapeId;
    _shapeId = value;
    onPropertyChanged(shapeIdPropertyKey, from, value);
    shapeIdChanged(from, value);
  }

  void shapeIdChanged(Id from, Id to);

  /// --------------------------------------------------------------------------
  /// ClipOpValue field with key 93.
  int _clipOpValue = 0;
  static const int clipOpValuePropertyKey = 93;

  /// Backing enum value for the clipping operation type (intersection or
  /// difference).
  int get clipOpValue => _clipOpValue;

  /// Change the [_clipOpValue] field value.
  /// [clipOpValueChanged] will be invoked only if the field's value has
  /// changed.
  set clipOpValue(int value) {
    if (_clipOpValue == value) {
      return;
    }
    int from = _clipOpValue;
    _clipOpValue = value;
    onPropertyChanged(clipOpValuePropertyKey, from, value);
    clipOpValueChanged(from, value);
  }

  void clipOpValueChanged(int from, int to);

  /// --------------------------------------------------------------------------
  /// IsVisible field with key 94.
  bool _isVisible = true;
  static const int isVisiblePropertyKey = 94;
  bool get isVisible => _isVisible;

  /// Change the [_isVisible] field value.
  /// [isVisibleChanged] will be invoked only if the field's value has changed.
  set isVisible(bool value) {
    if (_isVisible == value) {
      return;
    }
    bool from = _isVisible;
    _isVisible = value;
    onPropertyChanged(isVisiblePropertyKey, from, value);
    isVisibleChanged(from, value);
  }

  void isVisibleChanged(bool from, bool to);

  @override
  void changeNonNull() {
    super.changeNonNull();
    if (_shapeId != null) {
      onPropertyChanged(shapeIdPropertyKey, _shapeId, _shapeId);
    }
    if (_clipOpValue != null) {
      onPropertyChanged(clipOpValuePropertyKey, _clipOpValue, _clipOpValue);
    }
    if (_isVisible != null) {
      onPropertyChanged(isVisiblePropertyKey, _isVisible, _isVisible);
    }
  }

  @override
  void writeRuntimeProperties(BinaryWriter writer,
      HashMap<int, CoreFieldType> propertyToField, HashMap<Id, int> idLookup) {
    super.writeRuntimeProperties(writer, propertyToField, idLookup);
    if (_shapeId != null && exports(shapeIdPropertyKey)) {
      var value = idLookup[_shapeId];
      if (value != null) {
        context.uintType.writeRuntimeProperty(
            shapeIdPropertyKey, writer, value, propertyToField);
      }
    }
    if (_clipOpValue != null && exports(clipOpValuePropertyKey)) {
      context.uintType.writeRuntimeProperty(
          clipOpValuePropertyKey, writer, _clipOpValue, propertyToField);
    }
    if (_isVisible != null && exports(isVisiblePropertyKey)) {
      context.boolType.writeRuntimeProperty(
          isVisiblePropertyKey, writer, _isVisible, propertyToField);
    }
  }

  @override
  bool exports(int propertyKey) {
    switch (propertyKey) {
      case clipOpValuePropertyKey:
        return _clipOpValue != 0;
      case isVisiblePropertyKey:
        return _isVisible != true;
    }
    return super.exports(propertyKey);
  }

  @override
  K getProperty<K>(int propertyKey) {
    switch (propertyKey) {
      case shapeIdPropertyKey:
        return shapeId as K;
      case clipOpValuePropertyKey:
        return clipOpValue as K;
      case isVisiblePropertyKey:
        return isVisible as K;
      default:
        return super.getProperty<K>(propertyKey);
    }
  }

  @override
  bool hasProperty(int propertyKey) {
    switch (propertyKey) {
      case shapeIdPropertyKey:
      case clipOpValuePropertyKey:
      case isVisiblePropertyKey:
        return true;
      default:
        return super.hasProperty(propertyKey);
    }
  }
}
