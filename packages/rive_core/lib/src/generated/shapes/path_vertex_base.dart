/// Core automatically generated lib/src/generated/shapes/path_vertex_base.dart.
/// Do not modify manually.

import 'dart:collection';
import 'package:core/core.dart';
import 'package:core/key_state.dart';
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
  double _xAnimated;
  KeyState _xKeyState = KeyState.none;
  static const int xPropertyKey = 24;

  /// X value for the translation of the vertex.
  /// Get the [_x] field value.Note this may not match the core value if
  /// animation mode is active.
  double get x => _xAnimated ?? _x;

  /// Get the non-animation [_x] field value.
  double get xCore => _x;

  /// Change the [_x] field value.
  /// [xChanged] will be invoked only if the field's value has changed.
  set xCore(double value) {
    if (_x == value) {
      return;
    }
    double from = _x;
    _x = value;
    onPropertyChanged(xPropertyKey, from, value);
    xChanged(from, value);
  }

  set x(double value) {
    if (x == value) {
      return;
    }
    if (context != null && context.isAnimating) {
      _xAnimate(value, true);
      return;
    }
    xCore = value;
  }

  void _xAnimate(double value, bool autoKey) {
    if (_xAnimated == value) {
      return;
    }
    double from = x;
    _xAnimated = value;
    double to = x;
    onAnimatedPropertyChanged(xPropertyKey, autoKey, from, to);
    xChanged(from, to);
  }

  double get xAnimated => _xAnimated;
  set xAnimated(double value) => _xAnimate(value, false);
  KeyState get xKeyState => _xKeyState;
  set xKeyState(KeyState value) {
    if (_xKeyState == value) {
      return;
    }
    _xKeyState = value;
    // Force update anything listening on this property.
    onAnimatedPropertyChanged(xPropertyKey, false, _xAnimated, _xAnimated);
  }

  void xChanged(double from, double to);

  /// --------------------------------------------------------------------------
  /// Y field with key 25.
  double _y;
  double _yAnimated;
  KeyState _yKeyState = KeyState.none;
  static const int yPropertyKey = 25;

  /// Y value for the translation of the vertex.
  /// Get the [_y] field value.Note this may not match the core value if
  /// animation mode is active.
  double get y => _yAnimated ?? _y;

  /// Get the non-animation [_y] field value.
  double get yCore => _y;

  /// Change the [_y] field value.
  /// [yChanged] will be invoked only if the field's value has changed.
  set yCore(double value) {
    if (_y == value) {
      return;
    }
    double from = _y;
    _y = value;
    onPropertyChanged(yPropertyKey, from, value);
    yChanged(from, value);
  }

  set y(double value) {
    if (y == value) {
      return;
    }
    if (context != null && context.isAnimating) {
      _yAnimate(value, true);
      return;
    }
    yCore = value;
  }

  void _yAnimate(double value, bool autoKey) {
    if (_yAnimated == value) {
      return;
    }
    double from = y;
    _yAnimated = value;
    double to = y;
    onAnimatedPropertyChanged(yPropertyKey, autoKey, from, to);
    yChanged(from, to);
  }

  double get yAnimated => _yAnimated;
  set yAnimated(double value) => _yAnimate(value, false);
  KeyState get yKeyState => _yKeyState;
  set yKeyState(KeyState value) {
    if (_yKeyState == value) {
      return;
    }
    _yKeyState = value;
    // Force update anything listening on this property.
    onAnimatedPropertyChanged(yPropertyKey, false, _yAnimated, _yAnimated);
  }

  void yChanged(double from, double to);

  /// --------------------------------------------------------------------------
  /// Weights field with key 102.
  int _weights = 0;
  static const int weightsPropertyKey = 102;
  int get weights => _weights;

  /// Change the [_weights] field value.
  /// [weightsChanged] will be invoked only if the field's value has changed.
  set weights(int value) {
    if (_weights == value) {
      return;
    }
    int from = _weights;
    _weights = value;
    onPropertyChanged(weightsPropertyKey, from, value);
    weightsChanged(from, value);
  }

  void weightsChanged(int from, int to);

  /// --------------------------------------------------------------------------
  /// WeightIndices field with key 103.
  int _weightIndices = 0;
  static const int weightIndicesPropertyKey = 103;
  int get weightIndices => _weightIndices;

  /// Change the [_weightIndices] field value.
  /// [weightIndicesChanged] will be invoked only if the field's value has
  /// changed.
  set weightIndices(int value) {
    if (_weightIndices == value) {
      return;
    }
    int from = _weightIndices;
    _weightIndices = value;
    onPropertyChanged(weightIndicesPropertyKey, from, value);
    weightIndicesChanged(from, value);
  }

  void weightIndicesChanged(int from, int to);

  @override
  void changeNonNull() {
    super.changeNonNull();
    if (x != null) {
      onPropertyChanged(xPropertyKey, x, x);
    }
    if (y != null) {
      onPropertyChanged(yPropertyKey, y, y);
    }
    if (weights != null) {
      onPropertyChanged(weightsPropertyKey, weights, weights);
    }
    if (weightIndices != null) {
      onPropertyChanged(weightIndicesPropertyKey, weightIndices, weightIndices);
    }
  }

  @override
  void writeRuntimeProperties(BinaryWriter writer, HashMap<Id, int> idLookup) {
    super.writeRuntimeProperties(writer, idLookup);
    if (_x != null && exports(xPropertyKey)) {
      context.doubleType.writeRuntimeProperty(xPropertyKey, writer, _x);
    }
    if (_y != null && exports(yPropertyKey)) {
      context.doubleType.writeRuntimeProperty(yPropertyKey, writer, _y);
    }
    if (_weights != null && exports(weightsPropertyKey)) {
      context.uintType
          .writeRuntimeProperty(weightsPropertyKey, writer, _weights);
    }
    if (_weightIndices != null && exports(weightIndicesPropertyKey)) {
      context.uintType.writeRuntimeProperty(
          weightIndicesPropertyKey, writer, _weightIndices);
    }
  }

  @override
  bool exports(int propertyKey) {
    switch (propertyKey) {
      case weightsPropertyKey:
        return _weights != 0;
      case weightIndicesPropertyKey:
        return _weightIndices != 0;
    }
    return super.exports(propertyKey);
  }

  @override
  K getProperty<K>(int propertyKey) {
    switch (propertyKey) {
      case xPropertyKey:
        return x as K;
      case yPropertyKey:
        return y as K;
      case weightsPropertyKey:
        return weights as K;
      case weightIndicesPropertyKey:
        return weightIndices as K;
      default:
        return super.getProperty<K>(propertyKey);
    }
  }

  @override
  bool hasProperty(int propertyKey) {
    switch (propertyKey) {
      case xPropertyKey:
      case yPropertyKey:
      case weightsPropertyKey:
      case weightIndicesPropertyKey:
        return true;
      default:
        return super.hasProperty(propertyKey);
    }
  }
}
