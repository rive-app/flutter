/// Core automatically generated lib/src/generated/component_base.dart.
/// Do not modify manually.

import 'package:core/core.dart';

abstract class ComponentBase extends Core {
  /// --------------------------------------------------------------------------
  /// Name field with key 1.
  String _name;
  static const int namePropertyKey = 1;

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
  /// Parent field with key 2.
  int _parent;
  static const int parentPropertyKey = 2;

  /// Identifier used to track parent ContainerComponent.
  int get parent => _parent;

  /// Change the [_parent] field value.
  /// [parentChanged] will be invoked only if the field's value has changed.
  set parent(int value) {
    if (_parent == value) {
      return;
    }
    int from = _parent;
    _parent = value;
    parentChanged(from, value);
  }

  void parentChanged(int from, int to) {
    context?.changeProperty(this, parentPropertyKey, from, to);
  }

  /// --------------------------------------------------------------------------
  /// Order field with key 3.
  int _order;
  static const int orderPropertyKey = 3;

  /// Order value for sorting child elements in ContainerComponent parent.
  int get order => _order;

  /// Change the [_order] field value.
  /// [orderChanged] will be invoked only if the field's value has changed.
  set order(int value) {
    if (_order == value) {
      return;
    }
    int from = _order;
    _order = value;
    orderChanged(from, value);
  }

  void orderChanged(int from, int to) {
    context?.changeProperty(this, orderPropertyKey, from, to);
  }
}
