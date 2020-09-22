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
  /// SourceId field with key 92.
  Id _sourceId;
  static const int sourceIdPropertyKey = 92;

  /// Identifier used to track the node to use as a clipping source.
  Id get sourceId => _sourceId;

  /// Change the [_sourceId] field value.
  /// [sourceIdChanged] will be invoked only if the field's value has changed.
  set sourceId(Id value) {
    if (_sourceId == value) {
      return;
    }
    Id from = _sourceId;
    _sourceId = value;
    onPropertyChanged(sourceIdPropertyKey, from, value);
    sourceIdChanged(from, value);
  }

  void sourceIdChanged(Id from, Id to);

  /// --------------------------------------------------------------------------
  /// FillRule field with key 93.
  int _fillRule = 0;
  static const int fillRulePropertyKey = 93;

  /// Backing enum value for the clipping fill rule (nonZero or evenOdd).
  int get fillRule => _fillRule;

  /// Change the [_fillRule] field value.
  /// [fillRuleChanged] will be invoked only if the field's value has changed.
  set fillRule(int value) {
    if (_fillRule == value) {
      return;
    }
    int from = _fillRule;
    _fillRule = value;
    onPropertyChanged(fillRulePropertyKey, from, value);
    fillRuleChanged(from, value);
  }

  void fillRuleChanged(int from, int to);

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
    if (_sourceId != null) {
      onPropertyChanged(sourceIdPropertyKey, _sourceId, _sourceId);
    }
    if (_fillRule != null) {
      onPropertyChanged(fillRulePropertyKey, _fillRule, _fillRule);
    }
    if (_isVisible != null) {
      onPropertyChanged(isVisiblePropertyKey, _isVisible, _isVisible);
    }
  }

  @override
  void writeRuntimeProperties(BinaryWriter writer,
      HashMap<int, CoreFieldType> propertyToField, HashMap<Id, int> idLookup) {
    super.writeRuntimeProperties(writer, propertyToField, idLookup);
    if (_sourceId != null && exports(sourceIdPropertyKey)) {
      var value = idLookup[_sourceId];
      if (value != null) {
        context.uintType.writeRuntimeProperty(
            sourceIdPropertyKey, writer, value, propertyToField);
      }
    }
    if (_fillRule != null && exports(fillRulePropertyKey)) {
      context.uintType.writeRuntimeProperty(
          fillRulePropertyKey, writer, _fillRule, propertyToField);
    }
    if (_isVisible != null && exports(isVisiblePropertyKey)) {
      context.boolType.writeRuntimeProperty(
          isVisiblePropertyKey, writer, _isVisible, propertyToField);
    }
  }

  @override
  bool exports(int propertyKey) {
    switch (propertyKey) {
      case fillRulePropertyKey:
        return _fillRule != 0;
      case isVisiblePropertyKey:
        return _isVisible != true;
    }
    return super.exports(propertyKey);
  }

  @override
  K getProperty<K>(int propertyKey) {
    switch (propertyKey) {
      case sourceIdPropertyKey:
        return sourceId as K;
      case fillRulePropertyKey:
        return fillRule as K;
      case isVisiblePropertyKey:
        return isVisible as K;
      default:
        return super.getProperty<K>(propertyKey);
    }
  }

  @override
  bool hasProperty(int propertyKey) {
    switch (propertyKey) {
      case sourceIdPropertyKey:
      case fillRulePropertyKey:
      case isVisiblePropertyKey:
        return true;
      default:
        return super.hasProperty(propertyKey);
    }
  }
}
