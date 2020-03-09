import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fractional/fractional.dart';

/// A property item is a specialized item in the tree that we use to discern
/// whether the item should be drawn in a separate group from other children.
/// This is used in Rive for constraints, which like all components are stored
/// as children but are called out separately in the hierarchy for clarity. This
/// could be used for other features so it's generically referred to as a
/// property child.
class PropertyTreeItem extends TreeItem {
  PropertyTreeItem(String name, {List<TreeItem> children})
      : super(name, children: children);
}

/// Selection states are also entirely left up to the tree implementation, the
/// tree widget itself assumes nothing regarding selections. We chose to
/// implement it as an interface.
abstract class SelectableItem {
  ValueListenable<SelectionState> get selectionState;
  void select(SelectionState state);
}

enum SelectionState { selected, hovered, none }

/// Another example of a specialized tree item that should be drawn differently
/// in the tree. See the [MyTreeController] for how these are handled.
class SoloTreeItem extends TreeItem {
  SoloTreeItem(String name, {List<TreeItem> children})
      : super(name, children: children);
}

/// Base item for any node in the tree.
class TreeItem implements SelectableItem {
  final String name;
  TreeItemChildren children;

  /// The order of an item relative to its siblings is stored using a fraction.
  /// We use fractional indices (basically fractions less than 1) to allow for
  /// quick and individually precise movements within the tree. A regular index
  /// would require changing the index of all subsequent items if one item is
  /// moved to the top. A fractional index requires changing only the fraction
  /// of the first item and re-sorting the list. This allows for making
  /// concurrent changes that don't override other users' works.
  FractionalIndex index;

  TreeItem parent;

  final ValueNotifier<SelectionState> _selectionState =
      ValueNotifier<SelectionState>(SelectionState.none);

  TreeItem(this.name, {List<TreeItem> children}) {
    this.children ??= TreeItemChildren(children);
    for (final child in this.children) {
      child.parent = this;
    }
  }

  @override
  ValueListenable<SelectionState> get selectionState => _selectionState;
  @override
  void select(SelectionState state) {
    _selectionState.value = state;
  }

  @override
  String toString() {
    return name;
  }
}

/// Specialized fractionally indexed list, lets the list know where to get the
/// order of an item from.
class TreeItemChildren extends FractionallyIndexedList<TreeItem> {
  TreeItemChildren(List<TreeItem> items) : super(values: items);
  @override
  FractionalIndex orderOf(TreeItem value) {
    return value.index;
  }

  @override
  void setOrderOf(TreeItem value, FractionalIndex order) {
    value.index = order;
  }
}
