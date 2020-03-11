/// Core automatically generated lib/src/generated/shapes/path_vertex_base.dart.
/// Do not modify manually.

import 'package:meta/meta.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/src/generated/component_base.dart';

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
    xChanged(from, value);
  }

  @mustCallSuper
  void xChanged(double from, double to) {
    onPropertyChanged(xPropertyKey, from, to);
  }

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
    yChanged(from, value);
  }

  @mustCallSuper
  void yChanged(double from, double to) {
    onPropertyChanged(yPropertyKey, from, to);
  }

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
}
