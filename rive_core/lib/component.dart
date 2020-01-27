import 'package:rive_core/rive_file.dart';

import 'artboard.dart';
import 'container_component.dart';
import 'src/generated/component_base.dart';

class ComponentDirt {
  static const int dependents = 1 << 0;
}

abstract class Component extends ComponentBase<RiveFile> {
  Artboard _artboard;
  dynamic _userData;

  dynamic get userData => _userData;
  set userData(dynamic value) {
    if (value == _userData) {
      return;
    }
    dynamic last = _userData;
    _userData = value;
    userDataChanged(last, value);
  }

  void userDataChanged(dynamic from, dynamic to) {}

  @override
  void parentIdChanged(int from, int to) {
    super.parentIdChanged(from, to);
    var parent = context.objects[to];
    if (parent is ContainerComponent) {
      parent.addChild(this, updateIndex: false);
    }
  }

  ContainerComponent _parent;
  ContainerComponent get parent => _parent;
  set parent(ContainerComponent value) {
    if (_parent == value) {
      return;
    }
    var old = _parent;
    _parent = value;
    parentId = value.id;
    parentChanged(old, value);
  }

  void parentChanged(ContainerComponent from, ContainerComponent to) {}

  /// Components that depend on this component.
  final Set<Component> _dependents = {};

  /// Components that this component depends on.
  final Set<Component> _dependsOn = {};

  Set<Component> get dependents => _dependents;
  int _dirt = 0;

  bool addDependent(Component dependent) {
    if (!_dependents.add(dependent)) {
      dependent._dependsOn.add(this);
      return false;
    }
    _dirt |= ComponentDirt.dependents;
    context.markDependenciesDirty();

    return true;
  }

  void remove() {
    for (final parentDep in _dependsOn) {
      parentDep._dependents.remove(this);
    }
    _dependsOn.clear();
    _dirt |= ComponentDirt.dependents;
    context.markDependenciesDirty();
  }

  @override
  String toString() {
    return '${super.toString()} ($id)';
  }
}
