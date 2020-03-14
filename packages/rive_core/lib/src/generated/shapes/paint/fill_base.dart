/// Core automatically generated lib/src/generated/shapes/paint/fill_base.dart.
/// Do not modify manually.

import 'package:meta/meta.dart';
import 'package:rive_core/shapes/paint/shape_paint.dart';
import 'package:rive_core/src/generated/component_base.dart';
import 'package:rive_core/src/generated/container_component_base.dart';
import 'package:rive_core/src/generated/shapes/paint/shape_paint_base.dart';

abstract class FillBase extends ShapePaint {
  static const int typeKey = 20;
  @override
  int get coreType => FillBase.typeKey;
  @override
  Set<int> get coreTypes => {
        FillBase.typeKey,
        ShapePaintBase.typeKey,
        ContainerComponentBase.typeKey,
        ComponentBase.typeKey
      };

  /// --------------------------------------------------------------------------
  /// FillRule field with key 40.
  int _fillRule = 0;
  static const int fillRulePropertyKey = 40;
  int get fillRule => _fillRule;

  /// Change the [_fillRule] field value.
  /// [fillRuleChanged] will be invoked only if the field's value has changed.
  set fillRule(int value) {
    if (_fillRule == value) {
      return;
    }
    int from = _fillRule;
    _fillRule = value;
    fillRuleChanged(from, value);
  }

  @mustCallSuper
  void fillRuleChanged(int from, int to) {
    onPropertyChanged(fillRulePropertyKey, from, to);
  }

  @override
  void changeNonNull() {
    super.changeNonNull();
    if (fillRule != null) {
      onPropertyChanged(fillRulePropertyKey, fillRule, fillRule);
    }
  }

  @override
  K getProperty<K>(int propertyKey) {
    switch (propertyKey) {
      case fillRulePropertyKey:
        return fillRule as K;
      default:
        return super.getProperty<K>(propertyKey);
    }
  }
}
