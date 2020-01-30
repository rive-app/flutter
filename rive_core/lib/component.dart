import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
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

  // Used during update process.
  int graphOrder = 0;
  int dirt = 0;

  bool addDirt(int value, {bool recurse = false}) {
    if ((dirt & value) == value) {
      // Already marked.
      return false;
    }

    // Make sure dirt is set before calling anything that can set more dirt.
    dirt |= value;

    onDirty(dirt);
    artboard?.onComponentDirty(this);

    if (!recurse) {
      return true;
    }

    for (final d in dependents) {
      d.addDirt(value, recurse: recurse);
    }
    return true;
  }

  void onDirty(int mask) {}
  void update(int dirt);

  /// The artboard this component belongs to.
  Artboard get artboard;

  /// Find the artboard in the hierarchy.
  bool resolveArtboard();

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
    parent = context?.resolve(to);
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
    parentId = value?.id;
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
    // We need to resolve our artboard.
    markDependenciesDirty();
  }

  // @mustCallSuper
  // @protected
  // void markArtboardDirty() {
  //   context?.markArtboardDirty(this);
  // }

  /// Components that depend on this component.
  final Set<Component> _dependents = {};

  /// Components that this component depends on.
  final Set<Component> _dependsOn = {};

  Set<Component> get dependents => _dependents;
  // int _dirt = 0;

  bool addDependent(Component dependent) {
    assert(dependent != null, "Dependent cannot be null.");
    assert(artboard == dependent.artboard,
        "Components must be in the same artboard.");

    if (!_dependents.add(dependent)) {
      return false;
    }
    dependent._dependsOn.add(this);
    return true;
  }

  bool isValidParent(Component parent) => parent is ContainerComponent;

  void markDependenciesDirty() {
    context.markDependenciesDirty(this);
    for (final dependent in _dependents) {
      dependent.markDependenciesDirty();
    }
  }

  @mustCallSuper
  void buildDependencies() {
    for (final parentDep in _dependsOn) {
      parentDep._dependents.remove(this);
    }
    _dependsOn.clear();

    parent?.addDependent(this);
  }

  /// Something we depend on has been removed. It's important to clear out any
  /// stored references to that dependency so it can be garbage collected (if
  /// necessary).
  void onDependencyRemoved(Component dependent) {}

  void onRemoved() {
    for (final parentDep in _dependsOn) {
      parentDep._dependents.remove(this);
    }
    _dependsOn.clear();

    for (final dependent in _dependents) {
      dependent.onDependencyRemoved(this);
    }
    _dependents.clear();

    // silently clear from the parent in order to not cause any further undo
    // stack changes
    if (parent != null) {
      parent.children.remove(this);
      parent.childRemoved(this);
    }

    // The artboard containing this component will need it's dependencies
    // re-sorted.
    if (artboard != null) {
      context?.markDependencyOrderDirty(artboard);
    }
    // _dirt |= ComponentDirt.dependents;
    // parent?.children?.remove(this);
    // parent.childRemoved(this);
    // parentId = null;
    // var c = context;
    // context = null;
    // parentId = null;
    // context = c;
  }

  @override
  String toString() {
    return '${super.toString()} ($id)';
  }
}
