/// Core automatically generated lib/src/generated/shapes/points_path_base.dart.
/// Do not modify manually.

import 'package:meta/meta.dart';
import 'package:rive_core/shapes/path.dart';
import 'package:rive_core/src/generated/component_base.dart';
import 'package:rive_core/src/generated/container_component_base.dart';
import 'package:rive_core/src/generated/node_base.dart';
import 'package:rive_core/src/generated/shapes/path_base.dart';

abstract class PointsPathBase extends Path {
  static const int typeKey = 16;
  @override
  int get coreType => PointsPathBase.typeKey;
  @override
  Set<int> get coreTypes => {
        PointsPathBase.typeKey,
        PathBase.typeKey,
        NodeBase.typeKey,
        ContainerComponentBase.typeKey,
        ComponentBase.typeKey
      };

  /// --------------------------------------------------------------------------
  /// IsClosed field with key 32.
  bool _isClosed;
  static const int isClosedPropertyKey = 32;

  /// If the path should close back on its first vertex.
  bool get isClosed => _isClosed;

  /// Change the [_isClosed] field value.
  /// [isClosedChanged] will be invoked only if the field's value has changed.
  set isClosed(bool value) {
    if (_isClosed == value) {
      return;
    }
    bool from = _isClosed;
    _isClosed = value;
    isClosedChanged(from, value);
  }

  @mustCallSuper
  void isClosedChanged(bool from, bool to) {
    onPropertyChanged(isClosedPropertyKey, from, to);
  }

  @override
  void changeNonNull() {
    super.changeNonNull();
    if (isClosed != null) {
      onPropertyChanged(isClosedPropertyKey, isClosed, isClosed);
    }
  }

  @override
  K getProperty<K>(int propertyKey) {
    switch (propertyKey) {
      case isClosedPropertyKey:
        return isClosed as K;
      default:
        return super.getProperty<K>(propertyKey);
    }
  }
}
