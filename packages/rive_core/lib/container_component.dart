import 'package:flutter/material.dart';
import 'package:fractional/fractional.dart';
import 'component.dart';
import 'src/generated/container_component_base.dart';

class ContainerChildren extends FractionallyIndexedList<Component> {
  @override
  FractionalIndex orderOf(Component value) => value.childOrder;

  @override
  void setOrderOf(Component value, FractionalIndex order) {
    value.childOrder = order;
  }
}

typedef bool DescentCallback(Component component);

abstract class ContainerComponent extends ContainerComponentBase {
  final ContainerChildren children = ContainerChildren();

  void appendChild(Component child) {
    children.moveToEnd(child);
    child.parent = this;
  }

  // @override
  // void markArtboardDirty() {
  //   super.markArtboardDirty();
  //   for (final child in children) {
  //     child.markArtboardDirty();
  //   }
  // }

  // bool addChild(Component child, {bool updateIndex = true}) {
  //   assert(child != null);

  //   if (child.parent == this) {
  //     return false;
  //   }
  //   child.parent?.removeChild(child);
  //   child.parent = this;
  //   if (updateIndex) {
  //     children.append(child);
  //   } else {
  //     children.add(child);
  //   }

  //   // Let the context know that this item needs its children re-sorted.
  //   context?.markChildSortDirty(this);

  //   childAdded(child);
  //   return true;
  // }

  @mustCallSuper
  void childAdded(Component child) {
    context?.markChildSortDirty(this);
  }

  // bool removeChild(Component child) {
  //   assert(child != null);
  //   if (child.parent != this) {
  //     return false;
  //   }
  //   var removed = children.remove(child);
  //   childRemoved(child);
  //   return removed;
  // }

  void childRemoved(Component child) {}

  // Make sure that the current function can be applied to the current
  // [Component], before descending onto all the children.
  bool applyToAll(DescentCallback cb) {
    if (cb(this) == false) {
      return false;
    }
    applyToChildren(cb);
    return true;
  }

  // Recursively descend onto all the children in the hierarchy tree.
  // If the callback returns false, it won't recurse down a particular branch.
  void applyToChildren(DescentCallback cb) {
    for (final child in children) {
      if (cb(child) == false) {
        continue;
      }

      // TODO: replace with a more robust check.
      if (child is ContainerComponent) {
        child.applyToChildren(cb);
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
    applyToChildren((child) => deathRow.add(child));
    deathRow.forEach(context.remove);
  }
}
