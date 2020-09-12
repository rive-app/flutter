/// Core automatically generated lib/src/generated/draw_target_base.dart.
/// Do not modify manually.

import 'dart:collection';
import 'package:core/core.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/src/generated/component_base.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

abstract class DrawTargetBase extends Component {
  static const int typeKey = 48;
  @override
  int get coreType => DrawTargetBase.typeKey;
  @override
  Set<int> get coreTypes => {DrawTargetBase.typeKey, ComponentBase.typeKey};

  /// --------------------------------------------------------------------------
  /// DrawableId field with key 119.
  Id _drawableId;
  static const int drawableIdPropertyKey = 119;

  /// Id of the drawable this target references.
  Id get drawableId => _drawableId;

  /// Change the [_drawableId] field value.
  /// [drawableIdChanged] will be invoked only if the field's value has changed.
  set drawableId(Id value) {
    if (_drawableId == value) {
      return;
    }
    Id from = _drawableId;
    _drawableId = value;
    onPropertyChanged(drawableIdPropertyKey, from, value);
    drawableIdChanged(from, value);
  }

  void drawableIdChanged(Id from, Id to);

  /// --------------------------------------------------------------------------
  /// PlacementValue field with key 120.
  int _placementValue = 0;
  static const int placementValuePropertyKey = 120;

  /// Backing enum value for the Placement.
  int get placementValue => _placementValue;

  /// Change the [_placementValue] field value.
  /// [placementValueChanged] will be invoked only if the field's value has
  /// changed.
  set placementValue(int value) {
    if (_placementValue == value) {
      return;
    }
    int from = _placementValue;
    _placementValue = value;
    onPropertyChanged(placementValuePropertyKey, from, value);
    placementValueChanged(from, value);
  }

  void placementValueChanged(int from, int to);

  @override
  void changeNonNull() {
    super.changeNonNull();
    if (_drawableId != null) {
      onPropertyChanged(drawableIdPropertyKey, _drawableId, _drawableId);
    }
    if (_placementValue != null) {
      onPropertyChanged(
          placementValuePropertyKey, _placementValue, _placementValue);
    }
  }

  @override
  void writeRuntimeProperties(BinaryWriter writer, HashMap<Id, int> idLookup) {
    super.writeRuntimeProperties(writer, idLookup);
    if (_drawableId != null && exports(drawableIdPropertyKey)) {
      var value = idLookup[_drawableId];
      if (value != null) {
        context.uintType
            .writeRuntimeProperty(drawableIdPropertyKey, writer, value);
      }
    }
    if (_placementValue != null && exports(placementValuePropertyKey)) {
      context.uintType.writeRuntimeProperty(
          placementValuePropertyKey, writer, _placementValue);
    }
  }

  @override
  bool exports(int propertyKey) {
    switch (propertyKey) {
      case placementValuePropertyKey:
        return _placementValue != 0;
    }
    return super.exports(propertyKey);
  }

  @override
  K getProperty<K>(int propertyKey) {
    switch (propertyKey) {
      case drawableIdPropertyKey:
        return drawableId as K;
      case placementValuePropertyKey:
        return placementValue as K;
      default:
        return super.getProperty<K>(propertyKey);
    }
  }

  @override
  bool hasProperty(int propertyKey) {
    switch (propertyKey) {
      case drawableIdPropertyKey:
      case placementValuePropertyKey:
        return true;
      default:
        return super.hasProperty(propertyKey);
    }
  }
}
