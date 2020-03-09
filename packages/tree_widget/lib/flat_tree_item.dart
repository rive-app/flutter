import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Context used internally to flatten the tree.
class FlattenedTreeDataContext<T> {
  final Set<Object> expanded;
  int lastDepth = 0;
  FlatTreeItem<T> prev;

  FlattenedTreeDataContext(this.expanded);
}

/// Used to discern how a tree item is being targeted by a drag operation.
enum DropState { above, below, into, parent, none }

class _DropStateValueNotifier extends ValueNotifier<DropState> {
  Timer _delayParent;
  _DropStateValueNotifier() : super(DropState.none);
  @override
  set value(DropState newValue) {
    _delayParent?.cancel();
    if (newValue == super.value) {
      return;
    }
    _delayParent = null;
    if (newValue == DropState.parent) {
      _delayParent = Timer(const Duration(milliseconds: 400), () {
        super.value = DropState.parent;
      });
      super.value = DropState.none;
      return;
    }
    super.value = newValue;
  }
}

/// Tree data that has the hierarchy flattened, making it possible to render the
/// tree from virtualized (one dimensional) array.
class FlatTreeItem<T> {
  /// Key used to track the widget created for this item.
  final Key key;

  /// Reference back to the hierarchical node represented by this flat
  /// structure.
  final T data;

  /// Previous flattened sibling.
  final FlatTreeItem<T> prev;

  /// Next flattened sibling.
  FlatTreeItem<T> next;

  /// Parent [FlatTreeItem] from the hierarchy.
  final FlatTreeItem parent;

  /// Depths stored as a Uint8List. Each entry represents a horizontal space to
  /// move right by. If the entry is positive, a solid vertical line should also
  /// be drawn. This is used to connect up the lines in the hierarchy.
  Int8List depth;

  /// Whether this is the last of the siblings under [parent].
  bool isLastChild;

  /// Whether this item has more children which can be expanded.
  final bool hasChildren;

  /// Whether this item is expanded.
  final bool isExpanded;

  /// How many unit (line) spaces this column occupies.
  final int spacing;

  /// Whether this is item can be interacted with or not.
  final bool isDisabled;

  /// Whether this item is a property.
  final bool isProperty;

  /// The depth of where this item is dragged from. null when not dragged.
  int dragDepth;

  /// The observable drop state of this item.
  final ValueNotifier<DropState> dropState = _DropStateValueNotifier();

  FlatTreeItem(
    this.data, {
    this.parent,
    this.next,
    this.prev,
    this.depth,
    this.isLastChild,
    this.hasChildren,
    this.isExpanded,
    this.spacing,
    this.isDisabled,
    this.isProperty = false,
  }) : key = ValueKey(data);
}
