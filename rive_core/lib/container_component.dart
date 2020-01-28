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

abstract class ContainerComponent extends ContainerComponentBase {
  final ContainerChildren children = ContainerChildren();

  void appendChild(Component child) {
    children.moveToEnd(child);
    child.parent = this;
  }

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
}
