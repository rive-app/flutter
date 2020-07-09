import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:tree_widget/tree_widget.dart';

import 'flat_tree_item.dart';
import 'tree_style.dart';

/// The target for a drag operation comprised of an item of interest, where the
/// interest is described by state and a parent which is hierarchical parent in
/// the tree of the item.
class TreeDragOperationTarget<T> {
  final FlatTreeItem<T> item;
  final FlatTreeItem<T> parent;
  final DropState state;

  TreeDragOperationTarget({
    this.item,
    this.parent,
    this.state,
  });

  factory TreeDragOperationTarget.forItem(
      FlatTreeItem<T> item, DropState state) {
    if (item == null) {
      return null;
    }
    FlatTreeItem<T> parentTarget;
    if (item != null) {
      switch (state) {
        case DropState.below:
          if (item.isExpanded) {
            // The item is expanded so it becomes our parent target while the
            // first child becomes the item and we swap the state to be above
            // that item (as the parent is above it visually which was our
            // original target).
            parentTarget = item;
            state = DropState.above;
            item = item.next;
          } else {
            parentTarget = item.parent;
          }
          break;
        case DropState.above:
          parentTarget = item.parent;
          break;
        default:
          parentTarget = item;
          break;
      }
    }

    return TreeDragOperationTarget(
        parent: parentTarget, item: item, state: state);
  }

  @override
  String toString() => 'Drop Target: ${item.data} ${parent?.data} $state';

  void activate() {
    parent?.dropState?.value = DropState.parent;
    item?.dropState?.value = state;
  }

  void deactivate() {
    item?.dropState?.value = DropState.none;
    parent?.dropState?.value = DropState.none;
  }
}

class _TreeDragOperation<T> {
  final FlatTreeItem<T> startItem;
  final List<FlatTreeItem<T>> items;
  OverlayEntry overlayEntry;
  final ValueNotifier<Offset> offset = ValueNotifier<Offset>(Offset.zero);
  TreeDragOperationTarget<T> _target;
  TreeDragOperationTarget<T> get target => _target;

  void dropTarget(TreeDragOperationTarget<T> target) {
    _target?.deactivate();
    _target = target;
    _target?.activate();
  }

  void dispose() {
    _target?.deactivate();
    overlayEntry?.remove();
  }

  _TreeDragOperation(this.startItem, {this.items});
}

/// A helper to inherit from when creating a TreeView with hierarchical data.
/// This helper lets the implementation specify how items relate to each other
/// hierarchically without needing each item to implement any specific
/// interfaces.
abstract class TreeController<T> with ChangeNotifier {
  final HashSet<T> _expanded = HashSet<T>();
  List<FlatTreeItem<T>> _flat;
  HashMap<Key, int> _indexLookup = HashMap<Key, int>();
  HashMap<Key, int> get indexLookup => _indexLookup;

  Iterable<T> get data;

  _TreeDragOperation<T> _dragOperation;
  bool _needsFlattenAfterDrag = false;

  bool get isDragging => _dragOperation != null;
  _TreeDragOperation get dragOperation => _dragOperation;

  TreeController() {
    flatten();
  }

  /// The flattened data structure representing the hierarchical tree data that
  /// is currently expanded. This will be used by the TreeView to build a
  /// ListView with individual list items that connect via lines.
  List<FlatTreeItem<T>> get flat => _flat;

  /// Use this to opt out of flattening properties separately from other
  /// children. This is helpful when you have children that are of a different
  /// classification from others and want them to show up in a separate child
  /// sub-structure. If you know your tree won't need these, return false here
  /// to optimize away the extra computation needed to build these.
  bool get hasProperties => false;

  /// Return the children of T or null if none are available/treeItem doesn't
  /// have children.
  Iterable<T> childrenOf(T treeItem);

  HashSet<T> get expanded => _expanded;

  Set<T> recursiveChildrenOf(T treeItem) {
    Set<T> all = {};
    _recursiveChildrenOf(treeItem, all);
    return all;
  }

  void _recursiveChildrenOf(T treeItem, Set<T> all) {
    var children = childrenOf(treeItem);
    if (children == null) {
      return;
    }
    all.addAll(children);
    for (final child in children) {
      _recursiveChildrenOf(child, all);
    }
  }

  /// Hide the children of [item].
  void collapse(T item) {
    final expanded = _expanded;
    if (expanded.contains(item)) {
      expanded.remove(item);

      flatten();
    }
  }

  /// Show the children of [item].
  void expand(T item) {
    final expanded = _expanded;
    if (!expanded.contains(item)) {
      var children = childrenOf(item);
      if (children?.isNotEmpty ?? false) {
        expanded.add(item);
        flatten();
      }
    }
  }

  /// Show the item by expanding its parents
  void expandTo(T item) {
    for (final d in data) {
      final parents = _findParents(null, d, item);
      if (parents.isNotEmpty) {
        parents.forEach(expand);
        break;
      }
    }
  }

  List<T> _findParents(T parent, T child, T searchItem) {
    final children = childrenOf(child);
    if (searchItem == child) {
      return [parent];
    } else if (children.isEmpty) {
      return <T>[];
    } else {
      for (final item in children) {
        final foundParents = _findParents(child, item, searchItem);
        if (foundParents.isNotEmpty) {
          return foundParents..add(parent);
        }
      }
      // Not found, return an empty list
      return <T>[];
    }
  }

  /// Flatten the structure from a hierarchical tree with parent child
  /// relationships to a linear array with indentation properties. This also
  /// generates metadata for widgets to draw lines connecting the tree and it
  /// generates a key to index lookup which will be used in Flutter's ListView
  /// widget to remap rows when items get expanded and their indices inherently
  /// change.
  void flatten() {
    // assert(!isDragging);
    if (isDragging) {
      _needsFlattenAfterDrag = true;
      // Don't allow flatten during drag.
      return;
    }

    var flat = <FlatTreeItem<T>>[];
    var context = FlattenedTreeDataContext<T>(_expanded);
    var lookup = HashMap<Key, int>();

    _flatten(context, data, flat, lookup, [], null);
    _flat = flat;
    _indexLookup = lookup;
    notifyListeners();
  }

  /// Whether the [treeItem] is currently expanded
  bool isExpanded(T treeItem) {
    return expanded.contains(treeItem);
  }

  /// get a key that identifies the dataitem in this context
  dynamic dataKey(T treeItem) => treeItem.hashCode;

  /// Whether the [treeItem] can be interacted with.
  bool isDisabled(T treeItem);

  /// Return true if [treeItem] is a property and should be grouped separate
  /// from other children.
  bool isProperty(T treeItem);

  /// Called when the [item] has been dragged vertically. Returns items to start
  /// dragging.
  List<FlatTreeItem<T>> onDragStart(
      DragStartDetails details, FlatTreeItem<T> item);

  /// Called when the cursor hovers an item, use this to set any hover states
  /// you may want to track manually.
  void onMouseEnter(PointerEnterEvent event, FlatTreeItem<T> item);

  /// Called when the cursor leaves an item, use this to remove hover states you
  /// may want to track manually.
  void onMouseExit(PointerExitEvent event, FlatTreeItem<T> item);

  /// Override this to return whether or not the drop operation is allowed.
  bool allowDrop(
      TreeDragOperationTarget<T> target, List<FlatTreeItem<T>> items) {
    if (target.item.isDisabled || target.item.dragDepth != null) {
      return false;
    }
    return true;
  }

  /// Perform the drop operation (re-order items/children).
  void drop(TreeDragOperationTarget<T> target, List<FlatTreeItem<T>> items);

  /// Called when an item is tapped or clicked on.
  void onTap(FlatTreeItem<T> item) {
    T selectionPivot;
    if (isRangeSelecting && (selectionPivot = rangeSelectionPivot) != null) {
      var key = ValueKey(selectionPivot);
      var flatPivotIndex = indexLookup[key];
      if (flatPivotIndex != null) {
        var rangeToIndex = item.index;
        var startIndex = min(flatPivotIndex, rangeToIndex);
        var endIndex = max(flatPivotIndex, rangeToIndex);

        Set<T> toSelect = {};
        for (int i = startIndex; i <= endIndex; i++) {
          var flatItem = flat[i];
          toSelect.add(flatItem.data);
          if (!flatItem.isExpanded) {
            recursiveChildrenOf(flatItem.data).forEach(toSelect.add);
          }
        }
        selectMultipleTreeItems(toSelect);
        return;
      }
    }

    selectTreeItem(item.data);
  }

  /// Called when a right (secondary) click is received on an item. Should we
  /// consider renaming to onRequestContextMenu? We propagate the event so that
  /// implementations can get the global coordinates to show something like a
  /// popup menu.
  void onRightClick(
      BuildContext context, PointerDownEvent event, FlatTreeItem<T> item);

  /// The units of horizontal spacing occupied by [treeItem]. Most items consume
  /// 1 unit of horizontal spacing. 1 unit of horizontal spacing equates to the
  /// icon size + some padding. In some cases tree items need extra units when
  /// they display some extra content before the icon.
  ///
  /// For example, in Rive the Solo items have an extra toggle that should be
  /// drawn before the icon.
  ///
  /// ![](https://rive-app.github.io/assets-for-api-docs/assets/tree-widget-flutter/extra_spacing.png)
  int spacingOf(T treeItem);

  void startDrag(
      DragStartDetails details,
      BuildContext context,
      FlatTreeItem<T> dragStartItem,
      List<FlatTreeItem<T>> items,
      TreeViewDragBuilder<T> builder,
      TreeStyle style) {
    _dragOperation?.dispose();
    _dragOperation = _TreeDragOperation(dragStartItem, items: items);
    _dragOperation.offset.value = details.globalPosition;
    var dragOverlay = OverlayEntry(
      builder: (context) => ValueListenableBuilder<Offset>(
        valueListenable: _dragOperation.offset,
        builder: (context, position, _) => Positioned(
          left: position.dx - 200,
          width: 400,
          top: position.dy + 10,
          child: builder(context, items, style),
        ),
      ),
    );

    _dragOperation.overlayEntry = dragOverlay;

    Overlay.of(context).insert(dragOverlay);

    for (final item in items) {
      var dragDepth = item.depth.length;
      item.dragDepth = dragDepth;
      for (var next = item.next; next != null; next = next.next) {
        var p = next.parent;
        while (p != null) {
          if (p == item) {
            next.dragDepth = dragDepth;
            break;
          }
          p = p.parent;
        }
        if (p == null) {
          // item wasn't in our tree, we can early out from doing the rest.
          break;
        }
      }
    }
    notifyListeners();
  }

  void stopDrag() {
    var target = _dragOperation.target;
    var dropState = target?.state;
    var items = _dragOperation.items;

    _dragOperation.dispose();
    _dragOperation = null;
    for (final item in _flat) {
      item?.dragDepth = null;
    }

    if (target != null && dropState != null) {
      drop(target, items);
    }

    if (_needsFlattenAfterDrag) {
      _needsFlattenAfterDrag = false;
      flatten();
    } else {
      notifyListeners();
    }
  }

  void updateDrag(BuildContext itemContext, DragUpdateDetails details,
      FlatTreeItem<T> draggedItem, TreeStyle style) {
    _dragOperation.offset.value = details.globalPosition;

    // First find the fixed extent list renderer.
    RenderSliverFixedExtentList extentList;
    for (var p = itemContext.findRenderObject();
        p != null;
        p = p is RenderObject ? p.parent as RenderObject : null) {
      if (p is RenderSliverFixedExtentList) {
        extentList = p;
        break;
      }
    }
    if (extentList == null) {
      // We failed.
      return;
    }

    // Ok we've got an extent list. Get the first child and find its top.
    var first = extentList.firstChild;
    // We should always have children but maybe the list is fully collapsed?
    if (first != null) {
      // Compute the scroll offset of the first visible item (N.B. this is not
      // the first item in the list, it's the first one that's probably
      // visible).
      var offsetOfFirst = extentList.childScrollOffset(first);
      // We know this item's in the tree, so we can call globalToLocal on it.
      var local = first.globalToLocal(details.globalPosition);
      // Now we know where our cursor is relative to the first visible item.
      var y = offsetOfFirst + local.dy;
      // Compute index of item the cursor is over.
      var index = (y / style.itemHeight).floor();
      // Compute offset over that row (how close are we to the top of the row
      // we're hovering).
      var localOffset = y % style.itemHeight;

      // The rest is the same as before, use index to compute drop target.
      var dropTarget = index >= 0 && index < _flat.length ? _flat[index] : null;

      var state = localOffset < 10
          ? DropState.above
          : localOffset > style.itemHeight - 10
              ? DropState.below
              : DropState.into;

      var target = TreeDragOperationTarget.forItem(dropTarget, state);
      if (target != null && allowDrop(target, _dragOperation.items)) {
        _dragOperation.dropTarget(target);
      } else {
        _dragOperation.dropTarget(null);
      }
    }
  }

  void _flatten(
      FlattenedTreeDataContext<T> context,
      Iterable<T> data,
      List<FlatTreeItem<T>> flat,
      HashMap<Key, int> lookup,
      List<int> depth,
      FlatTreeItem<T> parent) {
    // int depthIndex = depth.length;
    // depth.add(spacing);

    Iterable<T> childItems;
    if (hasProperties) {
      var propertyChildItems = <T>[];
      childItems = propertyChildItems;
      List<T> propertyItems = [];
      for (final item in data) {
        if (isProperty(item)) {
          propertyItems.add(item);
          continue;
        }
        propertyChildItems.add(item);
      }
      int length = propertyItems.length;
      int childLength = childItems.length;
      for (int i = 0; i < length; i++) {
        var item = propertyItems[i];
        var spacing = spacingOf(item);
        var itemDepth = childLength == 0 ? depth + [1] : depth + [1, 1];

        var meta = FlatTreeItem<T>(
          item,
          index: flat.length,
          parent: parent,
          isProperty: true,
          prev: context.prev,
          next: null,
          depth: Int8List.fromList(itemDepth),
          isLastChild: i == length - 1,
          hasChildren: false,
          isExpanded: false,
          spacing: spacing,
          isDisabled: isDisabled(item),
        );
        if (context.prev != null) {
          context.prev.next = meta;
        }
        context.prev = meta;
        lookup[meta.key] = flat.length;
        flat.add(meta);
      }
    } else {
      childItems = data;
    }

    var childLength = childItems.length;
    int i = 0;
    for (final item in childItems) {
      // for (int i = 0; i < childLength; i++) {
      var isLast = i == childLength - 1;
      var spacing = spacingOf(item);
      var isExpanded = context.expanded.contains(item);
      var children = childrenOf(item);
      bool hasChildren = children?.isNotEmpty ?? false;
      var itemDepth = depth + [1];
      var meta = FlatTreeItem<T>(
        item,
        index: flat.length,
        parent: parent,
        prev: context.prev,
        next: null,
        depth: Int8List.fromList(itemDepth),
        isLastChild: isLast,
        hasChildren: hasChildren,
        isExpanded: hasChildren && isExpanded,
        spacing: spacing,
        isDisabled: isDisabled(item),
        isProperty: false,
      );
      if (context.prev != null) {
        context.prev.next = meta;
      }
      context.prev = meta;
      lookup[meta.key] = flat.length;
      flat.add(meta);
      if (isExpanded && hasChildren) {
        // update item depth for children
        int d = itemDepth.length - 1;
        if (spacing > 1) {
          itemDepth.add(-(spacing - 1));
        }
        itemDepth[d] = spacing < 0 || isLast ? -1 : 1;
        _flatten(
            context, children, flat, lookup, List<int>.from(itemDepth), meta);
      }
      i++;
    }
  }

  /// Refresh what is expanded, data has changed form underneath this
  /// controller.
  void refreshExpanded() {
    // data has changed
    final expandedKeys = <Object>{};
    flat.forEach((element) {
      if (isExpanded(element.data)) {
        expandedKeys.add(dataKey(element.data));
      }
    });
    _expanded.clear();

    data.forEach((_newDataRoot) {
      _walk<T>(_newDataRoot, childrenOf, (item) {
        if (expandedKeys.contains(dataKey(item))) {
          _expanded.add(item);
        }
      });
    });
    flatten();
  }

  bool hasHorizontalLine(T treeItem) => true;

  bool get isRangeSelecting => false;

  void selectTreeItem(T item) {}
  void selectMultipleTreeItems(Iterable<T> items) {}
  T get rangeSelectionPivot => null;
}

void _walk<T>(
    T root, Iterable<T> Function(T item) children, void Function(T item) cb) {
  cb(root);
  children(root).forEach((child) => _walk(child, children, cb));
}
