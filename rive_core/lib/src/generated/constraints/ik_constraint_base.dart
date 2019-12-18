/// Core automatically generated
/// lib/src/generated/constraints/ik_constraint_base.dart.
/// Do not modify manually.

import '../../../component.dart';

abstract class IkConstraintBase extends Component {
  static const int typeKey = 1;

  /// --------------------------------------------------------------------------
  /// Name field with key 4.
  String _name;
  static const int namePropertyKey = 4;
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
  /// Parent field with key 5.
  int _parent;
  static const int parentPropertyKey = 5;
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
}
