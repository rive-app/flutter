/// Core automatically generated
/// lib/src/generated/shapes/cubic_vertex_base.dart.
/// Do not modify manually.

import 'package:flutter/material.dart';
import '../../../shapes/path_vertex.dart';

abstract class CubicVertexBase extends PathVertex {
  static const int typeKey = 6;
  @override
  int get coreType => CubicVertexBase.typeKey;

  /// --------------------------------------------------------------------------
  /// InX field with key 27.
  double _inX;
  static const int inXPropertyKey = 27;

  /// In point's x value
  double get inX => _inX;

  /// Change the [_inX] field value.
  /// [inXChanged] will be invoked only if the field's value has changed.
  set inX(double value) {
    if (_inX == value) {
      return;
    }
    double from = _inX;
    _inX = value;
    inXChanged(from, value);
  }

  @mustCallSuper
  void inXChanged(double from, double to) {
    onPropertyChanged(inXPropertyKey, from, to);
  }

  /// --------------------------------------------------------------------------
  /// InY field with key 28.
  double _inY;
  static const int inYPropertyKey = 28;

  /// In point's y value
  double get inY => _inY;

  /// Change the [_inY] field value.
  /// [inYChanged] will be invoked only if the field's value has changed.
  set inY(double value) {
    if (_inY == value) {
      return;
    }
    double from = _inY;
    _inY = value;
    inYChanged(from, value);
  }

  @mustCallSuper
  void inYChanged(double from, double to) {
    onPropertyChanged(inYPropertyKey, from, to);
  }

  /// --------------------------------------------------------------------------
  /// OutX field with key 29.
  double _outX;
  static const int outXPropertyKey = 29;

  /// Out point's x value
  double get outX => _outX;

  /// Change the [_outX] field value.
  /// [outXChanged] will be invoked only if the field's value has changed.
  set outX(double value) {
    if (_outX == value) {
      return;
    }
    double from = _outX;
    _outX = value;
    outXChanged(from, value);
  }

  @mustCallSuper
  void outXChanged(double from, double to) {
    onPropertyChanged(outXPropertyKey, from, to);
  }

  /// --------------------------------------------------------------------------
  /// OutY field with key 30.
  double _outY;
  static const int outYPropertyKey = 30;

  /// Out point's y value
  double get outY => _outY;

  /// Change the [_outY] field value.
  /// [outYChanged] will be invoked only if the field's value has changed.
  set outY(double value) {
    if (_outY == value) {
      return;
    }
    double from = _outY;
    _outY = value;
    outYChanged(from, value);
  }

  @mustCallSuper
  void outYChanged(double from, double to) {
    onPropertyChanged(outYPropertyKey, from, to);
  }

  @override
  void changeNonNull() {
    super.changeNonNull();
    if (inX != null) {
      onPropertyChanged(inXPropertyKey, inX, inX);
    }
    if (inY != null) {
      onPropertyChanged(inYPropertyKey, inY, inY);
    }
    if (outX != null) {
      onPropertyChanged(outXPropertyKey, outX, outX);
    }
    if (outY != null) {
      onPropertyChanged(outYPropertyKey, outY, outY);
    }
  }

  @override
  K getProperty<K>(int propertyKey) {
    switch (propertyKey) {
      case inXPropertyKey:
        return inX as K;
      case inYPropertyKey:
        return inY as K;
      case outXPropertyKey:
        return outX as K;
      case outYPropertyKey:
        return outY as K;
      default:
        return super.getProperty<K>(propertyKey);
    }
  }
}
