/// Core automatically generated lib/src/generated/component_base.dart.
/// Do not modify manually.

import 'package:core/core.dart';
import 'rive_core_context.dart';

abstract class ComponentBase<T extends RiveCoreContext> extends Core<T> {
  /// --------------------------------------------------------------------------
  /// Name field with key 10.
  String _name;
  static const int namePropertyKey = 10;

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

  void nameChanged(String from, String to) {
    context?.changeProperty(this, namePropertyKey, from, to);
  }

  /// --------------------------------------------------------------------------
  /// ParentId field with key 11.
  int _parentId;
  static const int parentIdPropertyKey = 11;

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

  void parentIdChanged(int from, int to) {
    context?.changeProperty(this, parentIdPropertyKey, from, to);
  }

  /// --------------------------------------------------------------------------
  /// ChildOrder field with key 12.
  FractionalIndex _childOrder;
  static const int childOrderPropertyKey = 12;

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

  void childOrderChanged(FractionalIndex from, FractionalIndex to) {
    context?.changeProperty(this, childOrderPropertyKey, from, to);
  }

  @override
  void changeNonNull() {
    if (name != null) {
      context?.changeProperty(this, namePropertyKey, name, name);
    }
    if (parentId != null) {
      context?.changeProperty(this, parentIdPropertyKey, parentId, parentId);
    }
    if (childOrder != null) {
      context?.changeProperty(
          this, childOrderPropertyKey, childOrder, childOrder);
    }
  }
}
