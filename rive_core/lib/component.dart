import 'package:core/core.dart';
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

  /// The artboard this component belongs to.
  Artboard get artboard => _artboard;

  /// Find the artboard in the hierarchy.
  bool resolveArtboard() {
    for (var curr = parent; curr != null; curr = curr.parent) {
      if (curr is Artboard) {
        _artboard = curr;
        return true;
      }
    }
    _artboard = null;
    return false;
  }

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
    var p = context?.objects[to];
    if (p is ContainerComponent) {
      parent = p;
    }
  }

  @override
  void childOrderChanged(FractionalIndex from, FractionalIndex to) {
    super.childOrderChanged(from, to);

    if (parent != null) {
      // Let the context know that our parent needs to be re-sorted.
      context?.markChildSortDirty(parent);
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
    // TODO: what's the implication here? That id 0 is always a non-component?
    parentId = value?.id ?? 0;
    parentChanged(old, value);
  }

  void parentChanged(ContainerComponent from, ContainerComponent to) {
    if (from != null) {
      from.children.remove(this);
      from.childRemoved(this);
    }
    if (to != null) {
      to.children.add(this);
      to.childAdded(this);
    }
    // Let the context know that this item needs its artboard resolved.
    context?.markArtboardDirty(this);
  }

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
