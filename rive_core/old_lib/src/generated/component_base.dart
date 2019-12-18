/// Core automatically generated lib/src/generated/component_base.dart.
/// Do not modify manually.

abstract class ComponentBase extends Core {
  /// Non unique identifier, used to give friendly names to elements in the
  /// hierarchy. Runtimes provide an API for finding components by this name.
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

  /// Identifier used to track parent ContainerComponent.
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

  /// Order value for sorting child elements in ContainerComponent parent.
  int _order;
  int get order => _order;
  set order(int value) {
    if (_order == value) {
      return;
    }
    int from = _order;
    _order = value;
    _orderChanged(from, value);
  }

  void _orderChanged(int from, int to) {}
}
