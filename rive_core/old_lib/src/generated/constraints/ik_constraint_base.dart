/// Core automatically generated
/// lib/src/generated/constraints/ik_constraint_base.dart.
/// Do not modify manually.

import '../../../component.dart';

abstract class IkConstraintBase extends Component {
  String _name;
  String get name => _name;
  set name(String value) {
    if (_name == value) {
      return;
    }
    String from = _name;
    _name = value;
    _nameChanged(from, value);
  }

  void _nameChanged(String from, String to) {}
  int _parent;
  int get parent => _parent;
  set parent(int value) {
    if (_parent == value) {
      return;
    }
    int from = _parent;
    _parent = value;
    _parentChanged(from, value);
  }

  void _parentChanged(int from, int to) {}
}
