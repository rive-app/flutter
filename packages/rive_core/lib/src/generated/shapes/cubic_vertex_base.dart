/// Core automatically generated
/// lib/src/generated/shapes/cubic_vertex_base.dart.
/// Do not modify manually.

import 'dart:collection';
import 'package:core/core.dart';
import 'package:rive_core/shapes/path_vertex.dart';
import 'package:rive_core/src/generated/component_base.dart';
import 'package:rive_core/src/generated/shapes/path_vertex_base.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

abstract class CubicVertexBase extends PathVertex {
  static const int typeKey = 36;
  @override
  int get coreType => CubicVertexBase.typeKey;
  @override
  Set<int> get coreTypes =>
      {CubicVertexBase.typeKey, PathVertexBase.typeKey, ComponentBase.typeKey};

  /// --------------------------------------------------------------------------
  /// InWeights field with key 104.
  int _inWeights = 0;
  static const int inWeightsPropertyKey = 104;
  int get inWeights => _inWeights;

  /// Change the [_inWeights] field value.
  /// [inWeightsChanged] will be invoked only if the field's value has changed.
  set inWeights(int value) {
    if (_inWeights == value) {
      return;
    }
    int from = _inWeights;
    _inWeights = value;
    onPropertyChanged(inWeightsPropertyKey, from, value);
    inWeightsChanged(from, value);
  }

  void inWeightsChanged(int from, int to);

  /// --------------------------------------------------------------------------
  /// InWeightIndices field with key 105.
  int _inWeightIndices = 0;
  static const int inWeightIndicesPropertyKey = 105;
  int get inWeightIndices => _inWeightIndices;

  /// Change the [_inWeightIndices] field value.
  /// [inWeightIndicesChanged] will be invoked only if the field's value has
  /// changed.
  set inWeightIndices(int value) {
    if (_inWeightIndices == value) {
      return;
    }
    int from = _inWeightIndices;
    _inWeightIndices = value;
    onPropertyChanged(inWeightIndicesPropertyKey, from, value);
    inWeightIndicesChanged(from, value);
  }

  void inWeightIndicesChanged(int from, int to);

  /// --------------------------------------------------------------------------
  /// OutWeights field with key 106.
  int _outWeights = 0;
  static const int outWeightsPropertyKey = 106;
  int get outWeights => _outWeights;

  /// Change the [_outWeights] field value.
  /// [outWeightsChanged] will be invoked only if the field's value has changed.
  set outWeights(int value) {
    if (_outWeights == value) {
      return;
    }
    int from = _outWeights;
    _outWeights = value;
    onPropertyChanged(outWeightsPropertyKey, from, value);
    outWeightsChanged(from, value);
  }

  void outWeightsChanged(int from, int to);

  /// --------------------------------------------------------------------------
  /// OutWeightIndices field with key 107.
  int _outWeightIndices = 0;
  static const int outWeightIndicesPropertyKey = 107;
  int get outWeightIndices => _outWeightIndices;

  /// Change the [_outWeightIndices] field value.
  /// [outWeightIndicesChanged] will be invoked only if the field's value has
  /// changed.
  set outWeightIndices(int value) {
    if (_outWeightIndices == value) {
      return;
    }
    int from = _outWeightIndices;
    _outWeightIndices = value;
    onPropertyChanged(outWeightIndicesPropertyKey, from, value);
    outWeightIndicesChanged(from, value);
  }

  void outWeightIndicesChanged(int from, int to);

  @override
  void changeNonNull() {
    super.changeNonNull();
    if (inWeights != null) {
      onPropertyChanged(inWeightsPropertyKey, inWeights, inWeights);
    }
    if (inWeightIndices != null) {
      onPropertyChanged(
          inWeightIndicesPropertyKey, inWeightIndices, inWeightIndices);
    }
    if (outWeights != null) {
      onPropertyChanged(outWeightsPropertyKey, outWeights, outWeights);
    }
    if (outWeightIndices != null) {
      onPropertyChanged(
          outWeightIndicesPropertyKey, outWeightIndices, outWeightIndices);
    }
  }

  @override
  void writeRuntimeProperties(BinaryWriter writer, HashMap<Id, int> idLookup) {
    super.writeRuntimeProperties(writer, idLookup);
    if (_inWeights != null && exports(inWeightsPropertyKey)) {
      context.uintType
          .writeRuntimeProperty(inWeightsPropertyKey, writer, _inWeights);
    }
    if (_inWeightIndices != null && exports(inWeightIndicesPropertyKey)) {
      context.uintType.writeRuntimeProperty(
          inWeightIndicesPropertyKey, writer, _inWeightIndices);
    }
    if (_outWeights != null && exports(outWeightsPropertyKey)) {
      context.uintType
          .writeRuntimeProperty(outWeightsPropertyKey, writer, _outWeights);
    }
    if (_outWeightIndices != null && exports(outWeightIndicesPropertyKey)) {
      context.uintType.writeRuntimeProperty(
          outWeightIndicesPropertyKey, writer, _outWeightIndices);
    }
  }

  @override
  bool exports(int propertyKey) {
    switch (propertyKey) {
      case inWeightsPropertyKey:
        return _inWeights != 0;
      case inWeightIndicesPropertyKey:
        return _inWeightIndices != 0;
      case outWeightsPropertyKey:
        return _outWeights != 0;
      case outWeightIndicesPropertyKey:
        return _outWeightIndices != 0;
    }
    return super.exports(propertyKey);
  }

  @override
  K getProperty<K>(int propertyKey) {
    switch (propertyKey) {
      case inWeightsPropertyKey:
        return inWeights as K;
      case inWeightIndicesPropertyKey:
        return inWeightIndices as K;
      case outWeightsPropertyKey:
        return outWeights as K;
      case outWeightIndicesPropertyKey:
        return outWeightIndices as K;
      default:
        return super.getProperty<K>(propertyKey);
    }
  }

  @override
  bool hasProperty(int propertyKey) {
    switch (propertyKey) {
      case inWeightsPropertyKey:
      case inWeightIndicesPropertyKey:
      case outWeightsPropertyKey:
      case outWeightIndicesPropertyKey:
        return true;
      default:
        return super.hasProperty(propertyKey);
    }
  }
}
