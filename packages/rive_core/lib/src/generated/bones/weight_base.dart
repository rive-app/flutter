/// Core automatically generated lib/src/generated/bones/weight_base.dart.
/// Do not modify manually.

import 'dart:collection';
import 'package:core/core.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/src/generated/component_base.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

abstract class WeightBase extends Component {
  static const int typeKey = 45;
  @override
  int get coreType => WeightBase.typeKey;
  @override
  Set<int> get coreTypes => {WeightBase.typeKey, ComponentBase.typeKey};

  /// --------------------------------------------------------------------------
  /// Values field with key 102.
  int _values = 255;
  static const int valuesPropertyKey = 102;
  int get values => _values;

  /// Change the [_values] field value.
  /// [valuesChanged] will be invoked only if the field's value has changed.
  set values(int value) {
    if (_values == value) {
      return;
    }
    int from = _values;
    _values = value;
    onPropertyChanged(valuesPropertyKey, from, value);
    valuesChanged(from, value);
  }

  void valuesChanged(int from, int to);

  /// --------------------------------------------------------------------------
  /// Indices field with key 103.
  int _indices = 1;
  static const int indicesPropertyKey = 103;
  int get indices => _indices;

  /// Change the [_indices] field value.
  /// [indicesChanged] will be invoked only if the field's value has changed.
  set indices(int value) {
    if (_indices == value) {
      return;
    }
    int from = _indices;
    _indices = value;
    onPropertyChanged(indicesPropertyKey, from, value);
    indicesChanged(from, value);
  }

  void indicesChanged(int from, int to);

  @override
  void changeNonNull() {
    super.changeNonNull();
    if (_values != null) {
      onPropertyChanged(valuesPropertyKey, _values, _values);
    }
    if (_indices != null) {
      onPropertyChanged(indicesPropertyKey, _indices, _indices);
    }
  }

  @override
  void writeRuntimeProperties(BinaryWriter writer, HashMap<Id, int> idLookup) {
    super.writeRuntimeProperties(writer, idLookup);
    if (_values != null && exports(valuesPropertyKey)) {
      context.uintType.writeRuntimeProperty(valuesPropertyKey, writer, _values);
    }
    if (_indices != null && exports(indicesPropertyKey)) {
      context.uintType
          .writeRuntimeProperty(indicesPropertyKey, writer, _indices);
    }
  }

  @override
  bool exports(int propertyKey) {
    switch (propertyKey) {
      case valuesPropertyKey:
        return _values != 255;
      case indicesPropertyKey:
        return _indices != 1;
    }
    return super.exports(propertyKey);
  }

  @override
  K getProperty<K>(int propertyKey) {
    switch (propertyKey) {
      case valuesPropertyKey:
        return values as K;
      case indicesPropertyKey:
        return indices as K;
      default:
        return super.getProperty<K>(propertyKey);
    }
  }

  @override
  bool hasProperty(int propertyKey) {
    switch (propertyKey) {
      case valuesPropertyKey:
      case indicesPropertyKey:
        return true;
      default:
        return super.hasProperty(propertyKey);
    }
  }
}
