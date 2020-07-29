/// Core automatically generated lib/src/generated/shapes/points_path_base.dart.
/// Do not modify manually.

import 'dart:collection';
import 'package:core/core.dart';
import 'package:rive_core/shapes/path.dart';
import 'package:rive_core/src/generated/component_base.dart';
import 'package:rive_core/src/generated/container_component_base.dart';
import 'package:rive_core/src/generated/node_base.dart';
import 'package:rive_core/src/generated/shapes/path_base.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

abstract class PointsPathBase extends Path {
  static const int typeKey = 16;
  @override
  int get coreType => PointsPathBase.typeKey;
  @override
  Set<int> get coreTypes => {
        PointsPathBase.typeKey,
        PathBase.typeKey,
        NodeBase.typeKey,
        ContainerComponentBase.typeKey,
        ComponentBase.typeKey
      };

  /// --------------------------------------------------------------------------
  /// IsClosed field with key 32.
  bool _isClosed;
  static const int isClosedPropertyKey = 32;

  /// If the path should close back on its first vertex.
  @override
  bool get isClosed => _isClosed;

  /// Change the [_isClosed] field value.
  /// [isClosedChanged] will be invoked only if the field's value has changed.
  set isClosed(bool value) {
    if (_isClosed == value) {
      return;
    }
    bool from = _isClosed;
    _isClosed = value;
    onPropertyChanged(isClosedPropertyKey, from, value);
    isClosedChanged(from, value);
  }

  void isClosedChanged(bool from, bool to);

  /// --------------------------------------------------------------------------
  /// EditingModeValue field with key 74.
  int _editingModeValue = 0;
  static const int editingModeValuePropertyKey = 74;
  int get editingModeValue => _editingModeValue;

  /// Change the [_editingModeValue] field value.
  /// [editingModeValueChanged] will be invoked only if the field's value has
  /// changed.
  set editingModeValue(int value) {
    if (_editingModeValue == value) {
      return;
    }
    int from = _editingModeValue;
    _editingModeValue = value;
    onPropertyChanged(editingModeValuePropertyKey, from, value);
    context?.editorPropertyChanged(
        this, editingModeValuePropertyKey, from, value);
    editingModeValueChanged(from, value);
  }

  void editingModeValueChanged(int from, int to);

  @override
  void changeNonNull() {
    super.changeNonNull();
    if (isClosed != null) {
      onPropertyChanged(isClosedPropertyKey, isClosed, isClosed);
    }
    if (editingModeValue != null) {
      onPropertyChanged(
          editingModeValuePropertyKey, editingModeValue, editingModeValue);
    }
  }

  @override
  void writeRuntimeProperties(BinaryWriter writer, HashMap<Id, int> idLookup) {
    super.writeRuntimeProperties(writer, idLookup);
    if (_isClosed != null && exports(isClosedPropertyKey)) {
      context.boolType
          .writeRuntimeProperty(isClosedPropertyKey, writer, _isClosed);
    }
  }

  @override
  bool exports(int propertyKey) {
    switch (propertyKey) {
      case editingModeValuePropertyKey:
        return _editingModeValue != 0;
    }
    return super.exports(propertyKey);
  }

  @override
  K getProperty<K>(int propertyKey) {
    switch (propertyKey) {
      case isClosedPropertyKey:
        return isClosed as K;
      case editingModeValuePropertyKey:
        return editingModeValue as K;
      default:
        return super.getProperty<K>(propertyKey);
    }
  }

  @override
  bool hasProperty(int propertyKey) {
    switch (propertyKey) {
      case isClosedPropertyKey:
      case editingModeValuePropertyKey:
        return true;
      default:
        return super.hasProperty(propertyKey);
    }
  }
}
