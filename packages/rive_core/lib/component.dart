import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:rive_core/animation/keyframe.dart';
import 'package:rive_core/animation/linear_animation.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/rive_core_field_type.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/src/generated/component_base.dart';
import 'package:utilities/dependency_sorter.dart';
import 'package:utilities/tops.dart';
export 'package:rive_core/src/generated/component_base.dart';

// -> editor-only
final _log = Logger('rive_core');
// <- editor-only

abstract class Component extends ComponentBase<RiveFile>
    implements DependencyGraphNode<Component>, Parentable<Component> {
  Artboard _artboard;
  dynamic _userData;

  // -> editor-only
  String get timelineName => name;
  // TODO: implement this so things can be renamed in the timeline if this
  // canRename returns true.
  bool get canRename => true;

  String get defaultName => 'Component';

  @override
  String get name => super.name ?? defaultName;
  // <- editor-only

  /// Override to true if you want some object inheriting from Component to not
  /// have a parent. Most objects will validate that they have a parent during
  /// the onAdded callback otherwise they are considered invalid and are culled
  /// from core.
  bool get canBeOrphaned => false;

  // Used during update process.
  int graphOrder = 0;
  int dirt = 0xFFFF;

  // This is really only for sanity and earlying out of recursive loops.
  static const int maxTreeDepth = 5000;

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

  // Note that this isn't a setter as we don't want anything externally changing
  // the artboard.
  void _changeArtboard(Artboard value) {
    if (_artboard == value) {
      return;
    }
    _artboard?.removeComponent(this);
    _artboard = value;
    _artboard?.addComponent(this);
  }

  /// Called whenever we're resolving the artboard, we piggy back on that
  /// process to visit ancestors in the tree. This is a good opportunity to
  /// check if we have an ancestor of a specific type. For example, a Path needs
  /// to know which Shape it's within.
  void visitAncestor(Component ancestor) {}

  /// Find the artboard in the hierarchy.
  bool resolveArtboard() {
    int sanity = maxTreeDepth;
    for (Component curr = this;
        curr != null && sanity > 0;
        curr = curr.parent, sanity--) {
      visitAncestor(curr);
      if (curr is Artboard) {
        _changeArtboard(curr);
        return true;
      }
    }
    _changeArtboard(null);
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
    parent = context?.resolve(to);
  }

  // -> editor-only
  @override
  void childOrderChanged(FractionalIndex from, FractionalIndex to) {
    if (parent != null) {
      // Let the context know that our parent needs to be re-sorted.
      context?.markChildSortDirty(parent);
      artboard?.markNaturalDrawOrderDirty();
    }
  }
  // <- editor-only

  ContainerComponent _parent;
  @override
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

  @protected
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
    markRebuildDependencies();

    // -> editor-only
    artboard?.markNaturalDrawOrderDirty();
    // <- editor-only
  }

  /// Components that depend on this component.
  final Set<Component> _dependents = {};

  /// Components that this component depends on.
  final Set<Component> _dependsOn = {};

  @override
  Set<Component> get dependents => _dependents;

  // -> editor-only
  /// Override this to define a parent to group this component under.
  Component get timelineParent => null;

  /// Override this to bubble the properties of this component into another
  /// component.
  // ignore: avoid_returning_this
  Component get timelineProxy => this;

  String get timelineParentGroup => null;
  // <- editor-only

  bool addDependent(Component dependent) {
    assert(dependent != null, 'Dependent cannot be null.');
    assert(artboard == dependent.artboard,
        'Components must be in the same artboard.');

    if (!_dependents.add(dependent)) {
      return false;
    }
    dependent._dependsOn.add(this);
    // -> editor-only
    markRebuildDependentIds();
    // <- editor-only
    return true;
  }

  // -> editor-only
  void markRebuildDependentIds() {
    context?.markDependentIdsDirty(this);
  }
  // <- editor-only

  bool isValidParent(Component parent) => parent is ContainerComponent;

  void markRebuildDependencies() {
    if (context == null || !context.markDependenciesDirty(this)) {
      // no context, or already dirty.
      return;
    }
    for (final dependent in _dependents) {
      dependent.markRebuildDependencies();
    }
  }

  @mustCallSuper
  void buildDependencies() {
    for (final parentDep in _dependsOn) {
      parentDep._dependents.remove(this);
      // -> editor-only
      parentDep.markRebuildDependentIds();
      // <- editor-only
    }
    _dependsOn.clear();
    // by default a component depends on nothing (likely it will depend on the
    // parent but we leave that for specific implementations to supply).
  }

  /// Something we depend on has been removed. It's important to clear out any
  /// stored references to that dependency so it can be garbage collected (if
  /// necessary).
  void onDependencyRemoved(Component dependent) {}

  // -> editor-only
  @override
  bool validate() => parent != null || canBeOrphaned;
  // <- editor-only

  @override
  void onAdded() {}

  @override
  void onAddedDirty() {
    if (parentId != null) {
      parent = context?.resolve(parentId);
      // -> editor-only
      if (parent == null) {
        _log.finest('Failed to resolve parent with id $parentId');
      } else {
        // Make a best guess, this is useful when importing objects that are in
        // order as added, this ensures they'll get a valid sort order.
        childOrder ??= parent.children.nextFractionalIndex;
      }
      // <- editor-only
    }
  }

  /// When a component has been removed from the Core Context, we clean up any
  /// dangling references left on the parent and on any other dependent
  /// component. It's important for specialization of Component to respond to
  /// override [onDependencyRemoved] and clean up any further stored references
  /// to that component (for example the target of a Constraint).
  @override
  @mustCallSuper
  void onRemoved() {
    // -> editor-only
    var cbs = _whenRemoved.toList();
    _whenRemoved.clear();
    for (final cb in cbs) {
      cb();
    }
    // <- editor-only
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
      context?.markDependencyOrderDirty(
          // -> editor-only
          artboard
          // <- editor-only
          );
      _changeArtboard(null);
    }
  }

  @override
  String toString() {
    return '${super.toString()} ($id)';
  }

  /// Remove this component from the core system. This will unregister the
  /// component with the core context which does the work of synchronizing the
  /// removal from the system and then calling [onRemoved] on the Component when
  /// it's safe to clean up references to parents and anything that depends on
  /// this component.
  void remove() => context?.removeObject(this);

  // -> editor-only
  /// Create the corresponding keyframe for the property key. Note that this
  /// doesn't add it to core, that's left up to the implementation.
  T makeKeyFrame<T extends KeyFrame>(int propertyKey) {
    var coreType = context.coreType(propertyKey);
    if (coreType is KeyFrameGenerator<T>) {
      var keyFrame = (coreType as KeyFrameGenerator<T>).makeKeyFrame();
      return keyFrame;
    }
    return null;
  }

  /// Add a keyframe on this object for [propertyKey] at [time].
  T addKeyFrame<T extends KeyFrame>(
      LinearAnimation animation, int propertyKey, int frame) {
    assert(animation.artboard == artboard,
        'component is trying to key in an artboard that it doesn\'t belong to');
    assert(hasProperty(propertyKey),
        '$this doesn\'t store a property with key $propertyKey');
    var keyedObject = animation.getKeyed(this);
    keyedObject ??= animation.makeKeyed(this);
    var property = keyedObject.getKeyed(propertyKey);
    property ??= keyedObject.makeKeyed(propertyKey);

    // Need to see if we already have a keyframe at this time value, so might as
    // well search for it and store the index to insert the new one if we need
    // to.
    var keyFrameIndex = property.indexOfFrame(frame);

    if (keyFrameIndex < property.numFrames) {
      var keyFrame = property.getFrameAt(keyFrameIndex);
      if (keyFrame.frame == frame) {
        assert(keyFrame is T);
        return keyFrame as T;
      }
    }

    var keyFrame = makeKeyFrame<T>(propertyKey)
      ..frame = frame
      ..keyedPropertyId = property.id;
    context.addObject(keyFrame);
    return keyFrame;
  }

  @override
  void dependentIdsChanged(List<Id> from, List<Id> to) {
    /// Nothing to do when dependent ids changes, this is only used to propagate
    /// the ids to coop for validation during multi-session editing.
  }
  // <- editor-only

  @override
  void nameChanged(String from, String to) {
    /// Changing name doesn't really do anything.
  }

  // -> editor-only
  final Set<VoidCallback> _whenRemoved = {};
  bool whenRemoved(VoidCallback callback) => _whenRemoved.add(callback);

  bool cancelWhenRemoved(VoidCallback callback) =>
      _whenRemoved.remove(callback);

  int computeDepth() {
    int depth = 0;
    for (Component current = parent;
        current != null;
        current = current.parent) {
      depth++;
    }
    return depth;
  }
  // <- editor-only
}
