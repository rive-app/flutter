/// Core automatically generated
/// lib/src/generated/shapes/cubic_vertex_base.dart.
/// Do not modify manually.

import 'package:rive/rive_core/shapes/path_vertex.dart';
import 'package:rive/src/generated/component_base.dart';
import 'package:rive/src/generated/shapes/path_vertex_base.dart';

abstract class CubicVertexBase extends PathVertex {
  static const int typeKey = 6;
  @override
  int get coreType => CubicVertexBase.typeKey;
  @override
  Set<int> get coreTypes =>
      {CubicVertexBase.typeKey, PathVertexBase.typeKey, ComponentBase.typeKey};

  /// --------------------------------------------------------------------------
  /// ControlTypeValue field with key 75.
  int _controlTypeValue = 1;
  static const int controlTypeValuePropertyKey = 75;

  /// Backing integer value for the CubicControlType enum that describes how the
  /// handles move in relation to each other.
  int get controlTypeValue => _controlTypeValue;

  /// Change the [_controlTypeValue] field value.
  /// [controlTypeValueChanged] will be invoked only if the field's value has
  /// changed.
  set controlTypeValue(int value) {
    if (_controlTypeValue == value) {
      return;
    }
    int from = _controlTypeValue;
    _controlTypeValue = value;
    controlTypeValueChanged(from, value);
  }

  void controlTypeValueChanged(int from, int to);

  /// --------------------------------------------------------------------------
  /// InX field with key 27.
  double _inX = 0;
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

  void inXChanged(double from, double to);

  /// --------------------------------------------------------------------------
  /// InY field with key 28.
  double _inY = 0;
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

  void inYChanged(double from, double to);

  /// --------------------------------------------------------------------------
  /// OutX field with key 29.
  double _outX = 0;
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

  void outXChanged(double from, double to);

  /// --------------------------------------------------------------------------
  /// OutY field with key 30.
  double _outY = 0;
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

  void outYChanged(double from, double to);
}
