import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/draw_rules.dart';
import 'package:rive_core/drawable.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/src/generated/container_component_base.dart';

// -> editor-only
class ContainerChildren extends FractionallyIndexedList<Component> {
  @override
  FractionalIndex orderOf(Component value) => value.childOrder;

  ContainerChildren() : super();
  ContainerChildren.raw(List<Component> values) : super.raw(values);

  @override
  void setOrderOf(Component value, FractionalIndex order) {
    value.childOrder = order;
  }
}
// <- editor-only

typedef bool DescentCallback(Component component);

abstract class ContainerComponent extends ContainerComponentBase {
  final ContainerChildren children = ContainerChildren();

  void appendChild(Component child) {
    // -> editor-only
    children.moveToEnd(child);
    // <- editor-only
    child.parent = this;
  }

  @mustCallSuper
  void childAdded(Component child) {
    // -> editor-only
    context?.markChildSortDirty(this);
    // <- editor-only
  }

  void childRemoved(Component child) {}

  // -> editor-only
  void recomputeParentNodeBounds() {
    for (var p = this; p != null; p = p.parent) {
      if (p.coreType == NodeBase.typeKey) {
        (p as Node).markBoundsChanged();
      }
    }
  }
  // <- editor-only

  // Make sure that the current function can be applied to the current
  // [Component], before descending onto all the children.
  bool forAll(DescentCallback cb) {
    if (cb(this) == false) {
      return false;
    }
    forEachChild(cb);
    return true;
  }

  // Recursively descend onto all the children in the hierarchy tree.
  // If the callback returns false, it won't recurse down a particular branch.
  void forEachChild(DescentCallback cb) {
    for (final child in children) {
      if (cb(child) == false) {
        continue;
      }

      // TODO: replace with a more robust check.
      if (child is ContainerComponent) {
        child.forEachChild(cb);
      }
    }
  }

  /// Recursive version of [Component.remove]. This should only be called when
  /// you know this is the only part of the branch you are removing in your
  /// operation. If your operation could remove items from the same branch
  /// multiple times, you should consider building up a list of the individual
  /// items to remove and then remove them individually to avoid calling remove
  /// multiple times on children.
  void removeRecursive() {
    assert(context != null);

    Set<Component> deathRow = {this};
    forEachChild((child) => deathRow.add(child));
    deathRow.forEach(context.removeObject);
  }

  void buildDrawOrder(
      List<Drawable> drawables, DrawRules rules, List<DrawRules> allRules) {
    for (final child in children) {
      if (child is ContainerComponent) {
        child.buildDrawOrder(drawables, rules, allRules);
      }
    }
  }
}
