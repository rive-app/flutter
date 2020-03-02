/// Core automatically generated lib/src/generated/shapes/shape_base.dart.
/// Do not modify manually.

import 'package:flutter/material.dart';
import 'package:rive_core/drawable.dart';
import 'package:rive_core/src/generated/component_base.dart';
import 'package:rive_core/src/generated/container_component_base.dart';
import 'package:rive_core/src/generated/drawable_base.dart';
import 'package:rive_core/src/generated/node_base.dart';

abstract class ShapeBase extends Drawable {
  static const int typeKey = 3;
  @override
  int get coreType => ShapeBase.typeKey;
  @override
  Set<int> get coreTypes => {
        ShapeBase.typeKey,
        DrawableBase.typeKey,
        NodeBase.typeKey,
        ContainerComponentBase.typeKey,
        ComponentBase.typeKey
      };

  /// --------------------------------------------------------------------------
  /// TransformAffectsStroke field with key 19.
  bool _transformAffectsStroke;
  static const int transformAffectsStrokePropertyKey = 19;
  bool get transformAffectsStroke => _transformAffectsStroke;

  /// Change the [_transformAffectsStroke] field value.
  /// [transformAffectsStrokeChanged] will be invoked only if the field's value
  /// has changed.
  set transformAffectsStroke(bool value) {
    if (_transformAffectsStroke == value) {
      return;
    }
    bool from = _transformAffectsStroke;
    _transformAffectsStroke = value;
    transformAffectsStrokeChanged(from, value);
  }

  @mustCallSuper
  void transformAffectsStrokeChanged(bool from, bool to) {
    onPropertyChanged(transformAffectsStrokePropertyKey, from, to);
  }

  @override
  void changeNonNull() {
    super.changeNonNull();
    if (transformAffectsStroke != null) {
      onPropertyChanged(transformAffectsStrokePropertyKey,
          transformAffectsStroke, transformAffectsStroke);
    }
  }

  @override
  K getProperty<K>(int propertyKey) {
    switch (propertyKey) {
      case transformAffectsStrokePropertyKey:
        return transformAffectsStroke as K;
      default:
        return super.getProperty<K>(propertyKey);
    }
  }
}
