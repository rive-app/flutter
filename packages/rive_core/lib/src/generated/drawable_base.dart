/// Core automatically generated lib/src/generated/drawable_base.dart.
/// Do not modify manually.

import 'dart:collection';
import 'package:core/core.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/src/generated/component_base.dart';
import 'package:rive_core/src/generated/container_component_base.dart';
import 'package:rive_core/src/generated/node_base.dart';
import 'package:rive_core/src/generated/transform_component_base.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

abstract class DrawableBase extends Node {
  static const int typeKey = 13;
  @override
  int get coreType => DrawableBase.typeKey;
  @override
  Set<int> get coreTypes => {
        DrawableBase.typeKey,
        NodeBase.typeKey,
        TransformComponentBase.typeKey,
        ContainerComponentBase.typeKey,
        ComponentBase.typeKey
      };

  /// --------------------------------------------------------------------------
  /// DrawOrder field with key 22.
  FractionalIndex _drawOrder;
  static const int drawOrderPropertyKey = 22;
  FractionalIndex get drawOrder => _drawOrder;

  /// Change the [_drawOrder] field value.
  /// [drawOrderChanged] will be invoked only if the field's value has changed.
  set drawOrder(FractionalIndex value) {
    if (_drawOrder == value) {
      return;
    }
    FractionalIndex from = _drawOrder;
    _drawOrder = value;
    onPropertyChanged(drawOrderPropertyKey, from, value);
    drawOrderChanged(from, value);
  }

  void drawOrderChanged(FractionalIndex from, FractionalIndex to);

  /// --------------------------------------------------------------------------
  /// BlendModeValue field with key 23.
  int _blendModeValue = 3;
  static const int blendModeValuePropertyKey = 23;
  int get blendModeValue => _blendModeValue;

  /// Change the [_blendModeValue] field value.
  /// [blendModeValueChanged] will be invoked only if the field's value has
  /// changed.
  set blendModeValue(int value) {
    if (_blendModeValue == value) {
      return;
    }
    int from = _blendModeValue;
    _blendModeValue = value;
    onPropertyChanged(blendModeValuePropertyKey, from, value);
    blendModeValueChanged(from, value);
  }

  void blendModeValueChanged(int from, int to);

  @override
  void changeNonNull() {
    super.changeNonNull();
    if (drawOrder != null) {
      onPropertyChanged(drawOrderPropertyKey, drawOrder, drawOrder);
    }
    if (blendModeValue != null) {
      onPropertyChanged(
          blendModeValuePropertyKey, blendModeValue, blendModeValue);
    }
  }

  @override
  void writeRuntimeProperties(BinaryWriter writer, HashMap<Id, int> idLookup) {
    super.writeRuntimeProperties(writer, idLookup);
    if (_drawOrder != null && exports(drawOrderPropertyKey)) {
      var runtimeValue = runtimeValueDrawOrder(_drawOrder);
      context.uintType
          .writeRuntimeProperty(drawOrderPropertyKey, writer, runtimeValue);
    }
    if (_blendModeValue != null && exports(blendModeValuePropertyKey)) {
      context.uintType.writeRuntimeProperty(
          blendModeValuePropertyKey, writer, _blendModeValue);
    }
  }

  int runtimeValueDrawOrder(FractionalIndex editorValue);
  @override
  bool exports(int propertyKey) {
    switch (propertyKey) {
      case blendModeValuePropertyKey:
        return _blendModeValue != 3;
    }
    return super.exports(propertyKey);
  }

  @override
  K getProperty<K>(int propertyKey) {
    switch (propertyKey) {
      case drawOrderPropertyKey:
        return drawOrder as K;
      case blendModeValuePropertyKey:
        return blendModeValue as K;
      default:
        return super.getProperty<K>(propertyKey);
    }
  }

  @override
  bool hasProperty(int propertyKey) {
    switch (propertyKey) {
      case drawOrderPropertyKey:
      case blendModeValuePropertyKey:
        return true;
      default:
        return super.hasProperty(propertyKey);
    }
  }
}
