/// Core automatically generated lib/src/generated/component_base.dart.
/// Do not modify manually.

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:fractional/fractional.dart';
import 'rive_core_context.dart';

abstract class ComponentBase<T extends RiveCoreContext> extends Core<T> {
  /// --------------------------------------------------------------------------
  /// DependentIds field with key 3.
  List<int> _dependentIds;
  static const int dependentIdsPropertyKey = 3;

  /// List of integer ids for objects registered in the same context that depend
  /// on this object.
  List<int> get dependentIds => _dependentIds;

  /// Change the [_dependentIds] field value.
  /// [dependentIdsChanged] will be invoked only if the field's value has
  /// changed.
  set dependentIds(List<int> value) {
    if (listEquals(_dependentIds, value)) {
      return;
    }
    List<int> from = _dependentIds;
    _dependentIds = value;
    dependentIdsChanged(from, value);
  }

  @mustCallSuper
  void dependentIdsChanged(List<int> from, List<int> to) {
    onPropertyChanged(dependentIdsPropertyKey, from, to);
  }

  /// --------------------------------------------------------------------------
  /// Name field with key 4.
  String _name;
  static const int namePropertyKey = 4;

  /// Non-unique identifier, used to give friendly names to elements in the
  /// hierarchy. Runtimes provide an API for finding components by this [name].
  String get name => _name;

  /// Change the [_name] field value.
  /// [nameChanged] will be invoked only if the field's value has changed.
  set name(String value) {
    if (_name == value) {
      return;
    }
    String from = _name;
    _name = value;
    nameChanged(from, value);
  }

  @mustCallSuper
  void nameChanged(String from, String to) {
    onPropertyChanged(namePropertyKey, from, to);
  }

  /// --------------------------------------------------------------------------
  /// ParentId field with key 5.
  int _parentId;
  static const int parentIdPropertyKey = 5;

  /// Identifier used to track parent ContainerComponent.
  int get parentId => _parentId;

  /// Change the [_parentId] field value.
  /// [parentIdChanged] will be invoked only if the field's value has changed.
  set parentId(int value) {
    if (_parentId == value) {
      return;
    }
    int from = _parentId;
    _parentId = value;
    parentIdChanged(from, value);
  }

  @mustCallSuper
  void parentIdChanged(int from, int to) {
    onPropertyChanged(parentIdPropertyKey, from, to);
  }

  /// --------------------------------------------------------------------------
  /// ChildOrder field with key 6.
  FractionalIndex _childOrder;
  static const int childOrderPropertyKey = 6;

  /// Order value for sorting child elements in ContainerComponent parent.
  FractionalIndex get childOrder => _childOrder;

  /// Change the [_childOrder] field value.
  /// [childOrderChanged] will be invoked only if the field's value has changed.
  set childOrder(FractionalIndex value) {
    if (_childOrder == value) {
      return;
    }
    FractionalIndex from = _childOrder;
    _childOrder = value;
    childOrderChanged(from, value);
  }

  @mustCallSuper
  void childOrderChanged(FractionalIndex from, FractionalIndex to) {
    onPropertyChanged(childOrderPropertyKey, from, to);
  }

  @override
  void changeNonNull() {
    if (dependentIds != null) {
      onPropertyChanged(dependentIdsPropertyKey, dependentIds, dependentIds);
    }
    if (name != null) {
      onPropertyChanged(namePropertyKey, name, name);
    }
    if (parentId != null) {
      onPropertyChanged(parentIdPropertyKey, parentId, parentId);
    }
    if (childOrder != null) {
      onPropertyChanged(childOrderPropertyKey, childOrder, childOrder);
    }
  }

  @override
  K getProperty<K>(int propertyKey) {
    switch (propertyKey) {
      case dependentIdsPropertyKey:
        return dependentIds as K;
      case namePropertyKey:
        return name as K;
      case parentIdPropertyKey:
        return parentId as K;
      case childOrderPropertyKey:
        return childOrder as K;
      default:
        return super.getProperty<K>(propertyKey);
    }
  }
}
