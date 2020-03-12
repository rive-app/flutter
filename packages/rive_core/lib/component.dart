import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/shapes/ellipse.dart';
import 'package:rive_core/shapes/path.dart';
import 'package:rive_core/shapes/shape.dart';

import 'src/generated/component_base.dart';

export 'src/generated/component_base.dart';

final log = Logger('rive_core');

abstract class Component extends ComponentBase<RiveFile> {
  Artboard _artboard;
  dynamic _userData;

  // Used during update process.
  int graphOrder = 0;
  int dirt = 0;

  // Contains the Set of valid types for inherited classes.
  static final Map<Type, Set<Type>> validParents = {
    Node: {Artboard, Node, Shape},
    Path: {Shape, Node},
    Ellipse: {Shape, Node},
  };

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
  Artboard get artboard => _artboard;

  /// Called whenever we're resolving the artboard, we piggy back on that
  /// process to visit ancestors in the tree. This is a good opportunity to
  /// check if we have an ancestor of a specific type. For example, a Path needs
  /// to know which Shape it's within.
  void visitAncestor(Component ancestor) {}

  /// Find the artboard in the hierarchy.
  bool resolveArtboard() {
    log.finest("RESOLVING ARTBOARD FOR $name");
    for (Component curr = this; curr != null; curr = curr.parent) {
      visitAncestor(curr);
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
  void parentIdChanged(Id from, Id to) {
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
    markRebuildDependentIds();
    return true;
  }

  void markRebuildDependentIds() {
    context?.markDependentIdsDirty(this);
  }

  bool isValidParent(Component parent) => parent is ContainerComponent;

  void markDependenciesDirty() {
    context?.markDependenciesDirty(this);
    for (final dependent in _dependents) {
      dependent.markDependenciesDirty();
    }
  }

  @mustCallSuper
  void buildDependencies() {
    for (final parentDep in _dependsOn) {
      parentDep._dependents.remove(this);
      parentDep.markRebuildDependentIds();
    }
    _dependsOn.clear();
    // by default a component depends on nothing (likely it will depend on the
    // parent but we leave that for specific implementations to supply).
  }

  /// Something we depend on has been removed. It's important to clear out any
  /// stored references to that dependency so it can be garbage collected (if
  /// necessary).
  void onDependencyRemoved(Component dependent) {}

  void onAdded() {}

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
  }

  /// Override this to ascertain whether or not this object is in a valid state.
  /// If an object is in a corrupt state, it will be removed from core prior to
  /// calling onAdded for the object.
  bool validate() => true;

  @override
  String toString() {
    return '${super.toString()} ($id)';
  }
}
