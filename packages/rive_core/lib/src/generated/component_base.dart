/// Core automatically generated lib/src/generated/component_base.dart.
/// Do not modify manually.

import 'dart:collection';
import 'package:core/core.dart';
import 'package:core/field_types/core_field_type.dart';
import 'package:rive_core/src/generated/rive_core_context.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

abstract class ComponentBase<T extends RiveCoreContext> extends Core<T> {
  static const int typeKey = 10;
  @override
  int get coreType => ComponentBase.typeKey;
  @override
  Set<int> get coreTypes => {ComponentBase.typeKey};

  /// --------------------------------------------------------------------------
  /// DependentIds field with key 3.
  List<Id> _dependentIds;
  static const int dependentIdsPropertyKey = 3;

  /// List of integer ids for objects registered in the same context that depend
  /// on this object.
  List<Id> get dependentIds => _dependentIds;

  /// Change the [_dependentIds] field value.
  /// [dependentIdsChanged] will be invoked only if the field's value has
  /// changed.
  set dependentIds(List<Id> value) {
    if (listEquals(_dependentIds, value)) {
      return;
    }
    List<Id> from = _dependentIds;
    _dependentIds = value;
    onPropertyChanged(dependentIdsPropertyKey, from, value);
    dependentIdsChanged(from, value);
  }

  void dependentIdsChanged(List<Id> from, List<Id> to);

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
    onPropertyChanged(namePropertyKey, from, value);
    nameChanged(from, value);
  }

  void nameChanged(String from, String to);

  /// --------------------------------------------------------------------------
  /// ParentId field with key 5.
  Id _parentId;
  static const int parentIdPropertyKey = 5;

  /// Identifier used to track parent ContainerComponent.
  Id get parentId => _parentId;

  /// Change the [_parentId] field value.
  /// [parentIdChanged] will be invoked only if the field's value has changed.
  set parentId(Id value) {
    if (_parentId == value) {
      return;
    }
    Id from = _parentId;
    _parentId = value;
    onPropertyChanged(parentIdPropertyKey, from, value);
    parentIdChanged(from, value);
  }

  void parentIdChanged(Id from, Id to);

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
    onPropertyChanged(childOrderPropertyKey, from, value);
    childOrderChanged(from, value);
  }

  void childOrderChanged(FractionalIndex from, FractionalIndex to);

  @override
  void changeNonNull() {
    if (_dependentIds != null) {
      onPropertyChanged(dependentIdsPropertyKey, _dependentIds, _dependentIds);
    }
    if (_name != null) {
      onPropertyChanged(namePropertyKey, _name, _name);
    }
    if (_parentId != null) {
      onPropertyChanged(parentIdPropertyKey, _parentId, _parentId);
    }
    if (_childOrder != null) {
      onPropertyChanged(childOrderPropertyKey, _childOrder, _childOrder);
    }
  }

  @override
  void writeRuntimeProperties(BinaryWriter writer,
      HashMap<int, CoreFieldType> propertyToField, HashMap<Id, int> idLookup) {
    if (_name != null && exports(namePropertyKey)) {
      context.stringType.writeRuntimeProperty(
          namePropertyKey, writer, _name, propertyToField);
    }
    if (_parentId != null && exports(parentIdPropertyKey)) {
      var value = idLookup[_parentId];
      if (value != null) {
        context.uintType.writeRuntimeProperty(
            parentIdPropertyKey, writer, value, propertyToField);
      }
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

  @override
  bool hasProperty(int propertyKey) {
    switch (propertyKey) {
      case dependentIdsPropertyKey:
      case namePropertyKey:
      case parentIdPropertyKey:
      case childOrderPropertyKey:
        return true;
      default:
        return super.hasProperty(propertyKey);
    }
  }
}
