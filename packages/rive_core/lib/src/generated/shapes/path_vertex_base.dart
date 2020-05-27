/// Core automatically generated lib/src/generated/shapes/path_vertex_base.dart.
/// Do not modify manually.

import 'dart:collection';
import 'package:core/core.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/src/generated/component_base.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

abstract class PathVertexBase extends Component {
  static const int typeKey = 14;
  @override
  int get coreType => PathVertexBase.typeKey;
  @override
  Set<int> get coreTypes => {PathVertexBase.typeKey, ComponentBase.typeKey};

  /// --------------------------------------------------------------------------
  /// X field with key 24.
  double _x;
  static const int xPropertyKey = 24;

  /// X value for the translation of the vertex.
  double get x => _x;

  /// Change the [_x] field value.
  /// [xChanged] will be invoked only if the field's value has changed.
  set x(double value) {
    if (_x == value) {
      return;
    }
    double from = _x;
    _x = value;
    onPropertyChanged(xPropertyKey, from, value);
    xChanged(from, value);
  }

  void xChanged(double from, double to);

  /// --------------------------------------------------------------------------
  /// Y field with key 25.
  double _y;
  static const int yPropertyKey = 25;

  /// Y value for the translation of the vertex.
  double get y => _y;

  /// Change the [_y] field value.
  /// [yChanged] will be invoked only if the field's value has changed.
  set y(double value) {
    if (_y == value) {
      return;
    }
    double from = _y;
    _y = value;
    onPropertyChanged(yPropertyKey, from, value);
    yChanged(from, value);
  }

  void yChanged(double from, double to);

  @override
  void changeNonNull() {
    super.changeNonNull();
    if (x != null) {
      onPropertyChanged(xPropertyKey, x, x);
    }
    if (y != null) {
      onPropertyChanged(yPropertyKey, y, y);
    }
  }

  @override
  void writeRuntimeProperties(BinaryWriter writer, HashMap<Id, int> idLookup) {
    super.writeRuntimeProperties(writer, idLookup);
    if (_x != null) {
      context.doubleType.writeProperty(xPropertyKey, writer, _x);
    }
    if (_y != null) {
      context.doubleType.writeProperty(yPropertyKey, writer, _y);
    }
  }

  @override
  K getProperty<K>(int propertyKey) {
    switch (propertyKey) {
      case xPropertyKey:
        return x as K;
      case yPropertyKey:
        return y as K;
      default:
        return super.getProperty<K>(propertyKey);
    }
  }

  @override
  bool hasProperty(int propertyKey) {
    switch (propertyKey) {
      case xPropertyKey:
      case yPropertyKey:
        return true;
      default:
        return super.hasProperty(propertyKey);
    }
  }
}
