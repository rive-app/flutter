/// Core automatically generated
/// lib/src/generated/shapes/paint/trim_path_base.dart.
/// Do not modify manually.

import 'dart:collection';
import 'package:core/core.dart';
import 'package:core/key_state.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/src/generated/component_base.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

abstract class TrimPathBase extends Component {
  static const int typeKey = 47;
  @override
  int get coreType => TrimPathBase.typeKey;
  @override
  Set<int> get coreTypes => {TrimPathBase.typeKey, ComponentBase.typeKey};

  /// --------------------------------------------------------------------------
  /// Start field with key 114.
  double _start = 0;
  double _startAnimated;
  KeyState _startKeyState = KeyState.none;
  static const int startPropertyKey = 114;

  /// Get the [_start] field value.Note this may not match the core value if
  /// animation mode is active.
  double get start => _startAnimated ?? _start;

  /// Get the non-animation [_start] field value.
  double get startCore => _start;

  /// Change the [_start] field value.
  /// [startChanged] will be invoked only if the field's value has changed.
  set startCore(double value) {
    if (_start == value) {
      return;
    }
    double from = _start;
    _start = value;
    onPropertyChanged(startPropertyKey, from, value);
    startChanged(from, value);
  }

  set start(double value) {
    if (start == value) {
      return;
    }
    if (context != null && context.isAnimating) {
      _startAnimate(value, true);
      return;
    }
    startCore = value;
  }

  void _startAnimate(double value, bool autoKey) {
    if (_startAnimated == value) {
      return;
    }
    double from = start;
    _startAnimated = value;
    double to = start;
    onAnimatedPropertyChanged(startPropertyKey, autoKey, from, to);
    startChanged(from, to);
  }

  double get startAnimated => _startAnimated;
  set startAnimated(double value) => _startAnimate(value, false);
  KeyState get startKeyState => _startKeyState;
  set startKeyState(KeyState value) {
    if (_startKeyState == value) {
      return;
    }
    _startKeyState = value;
    // Force update anything listening on this property.
    onAnimatedPropertyChanged(
        startPropertyKey, false, _startAnimated, _startAnimated);
  }

  void startChanged(double from, double to);

  /// --------------------------------------------------------------------------
  /// End field with key 115.
  double _end = 0;
  double _endAnimated;
  KeyState _endKeyState = KeyState.none;
  static const int endPropertyKey = 115;

  /// Get the [_end] field value.Note this may not match the core value if
  /// animation mode is active.
  double get end => _endAnimated ?? _end;

  /// Get the non-animation [_end] field value.
  double get endCore => _end;

  /// Change the [_end] field value.
  /// [endChanged] will be invoked only if the field's value has changed.
  set endCore(double value) {
    if (_end == value) {
      return;
    }
    double from = _end;
    _end = value;
    onPropertyChanged(endPropertyKey, from, value);
    endChanged(from, value);
  }

  set end(double value) {
    if (end == value) {
      return;
    }
    if (context != null && context.isAnimating) {
      _endAnimate(value, true);
      return;
    }
    endCore = value;
  }

  void _endAnimate(double value, bool autoKey) {
    if (_endAnimated == value) {
      return;
    }
    double from = end;
    _endAnimated = value;
    double to = end;
    onAnimatedPropertyChanged(endPropertyKey, autoKey, from, to);
    endChanged(from, to);
  }

  double get endAnimated => _endAnimated;
  set endAnimated(double value) => _endAnimate(value, false);
  KeyState get endKeyState => _endKeyState;
  set endKeyState(KeyState value) {
    if (_endKeyState == value) {
      return;
    }
    _endKeyState = value;
    // Force update anything listening on this property.
    onAnimatedPropertyChanged(
        endPropertyKey, false, _endAnimated, _endAnimated);
  }

  void endChanged(double from, double to);

  /// --------------------------------------------------------------------------
  /// Offset field with key 116.
  double _offset = 0;
  double _offsetAnimated;
  KeyState _offsetKeyState = KeyState.none;
  static const int offsetPropertyKey = 116;

  /// Get the [_offset] field value.Note this may not match the core value if
  /// animation mode is active.
  double get offset => _offsetAnimated ?? _offset;

  /// Get the non-animation [_offset] field value.
  double get offsetCore => _offset;

  /// Change the [_offset] field value.
  /// [offsetChanged] will be invoked only if the field's value has changed.
  set offsetCore(double value) {
    if (_offset == value) {
      return;
    }
    double from = _offset;
    _offset = value;
    onPropertyChanged(offsetPropertyKey, from, value);
    offsetChanged(from, value);
  }

  set offset(double value) {
    if (offset == value) {
      return;
    }
    if (context != null && context.isAnimating) {
      _offsetAnimate(value, true);
      return;
    }
    offsetCore = value;
  }

  void _offsetAnimate(double value, bool autoKey) {
    if (_offsetAnimated == value) {
      return;
    }
    double from = offset;
    _offsetAnimated = value;
    double to = offset;
    onAnimatedPropertyChanged(offsetPropertyKey, autoKey, from, to);
    offsetChanged(from, to);
  }

  double get offsetAnimated => _offsetAnimated;
  set offsetAnimated(double value) => _offsetAnimate(value, false);
  KeyState get offsetKeyState => _offsetKeyState;
  set offsetKeyState(KeyState value) {
    if (_offsetKeyState == value) {
      return;
    }
    _offsetKeyState = value;
    // Force update anything listening on this property.
    onAnimatedPropertyChanged(
        offsetPropertyKey, false, _offsetAnimated, _offsetAnimated);
  }

  void offsetChanged(double from, double to);

  /// --------------------------------------------------------------------------
  /// ModeValue field with key 117.
  int _modeValue = 0;
  static const int modeValuePropertyKey = 117;
  int get modeValue => _modeValue;

  /// Change the [_modeValue] field value.
  /// [modeValueChanged] will be invoked only if the field's value has changed.
  set modeValue(int value) {
    if (_modeValue == value) {
      return;
    }
    int from = _modeValue;
    _modeValue = value;
    onPropertyChanged(modeValuePropertyKey, from, value);
    modeValueChanged(from, value);
  }

  void modeValueChanged(int from, int to);

  @override
  void changeNonNull() {
    super.changeNonNull();
    if (start != null) {
      onPropertyChanged(startPropertyKey, start, start);
    }
    if (end != null) {
      onPropertyChanged(endPropertyKey, end, end);
    }
    if (offset != null) {
      onPropertyChanged(offsetPropertyKey, offset, offset);
    }
    if (modeValue != null) {
      onPropertyChanged(modeValuePropertyKey, modeValue, modeValue);
    }
  }

  @override
  void writeRuntimeProperties(BinaryWriter writer, HashMap<Id, int> idLookup) {
    super.writeRuntimeProperties(writer, idLookup);
    if (_start != null && exports(startPropertyKey)) {
      context.doubleType.writeRuntimeProperty(startPropertyKey, writer, _start);
    }
    if (_end != null && exports(endPropertyKey)) {
      context.doubleType.writeRuntimeProperty(endPropertyKey, writer, _end);
    }
    if (_offset != null && exports(offsetPropertyKey)) {
      context.doubleType
          .writeRuntimeProperty(offsetPropertyKey, writer, _offset);
    }
    if (_modeValue != null && exports(modeValuePropertyKey)) {
      context.uintType
          .writeRuntimeProperty(modeValuePropertyKey, writer, _modeValue);
    }
  }

  @override
  bool exports(int propertyKey) {
    switch (propertyKey) {
      case startPropertyKey:
        return _start != 0;
      case endPropertyKey:
        return _end != 0;
      case offsetPropertyKey:
        return _offset != 0;
      case modeValuePropertyKey:
        return _modeValue != 0;
    }
    return super.exports(propertyKey);
  }

  @override
  K getProperty<K>(int propertyKey) {
    switch (propertyKey) {
      case startPropertyKey:
        return start as K;
      case endPropertyKey:
        return end as K;
      case offsetPropertyKey:
        return offset as K;
      case modeValuePropertyKey:
        return modeValue as K;
      default:
        return super.getProperty<K>(propertyKey);
    }
  }

  @override
  bool hasProperty(int propertyKey) {
    switch (propertyKey) {
      case startPropertyKey:
      case endPropertyKey:
      case offsetPropertyKey:
      case modeValuePropertyKey:
        return true;
      default:
        return super.hasProperty(propertyKey);
    }
  }
}
