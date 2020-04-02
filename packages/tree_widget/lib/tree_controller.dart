import 'dart:collection';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'flat_tree_item.dart';
import 'tree_style.dart';

class _TreeDragOperation<T> {
  final FlatTreeItem<T> startItem;
  final List<FlatTreeItem<T>> items;
  OverlayEntry overlayEntry;
  final ValueNotifier<Offset> offset = ValueNotifier<Offset>(Offset.zero);
  FlatTreeItem<T> _target;
  FlatTreeItem<T> get target => _target;

  void dropTarget(FlatTreeItem<T> target, DropState state) {
    if (_target != target) {
      _target?.parent?.dropState?.value = DropState.none;
      _target?.dropState?.value = DropState.none;
    } else if (_target != null && _target.dropState.value == state) {
      return;
    }
    _target = target;
    if (target != null) {
      target.dropState?.value = state;
      switch (state) {
        case DropState.below:
        case DropState.above:
          target.parent?.dropState?.value = DropState.parent;
          break;
        default:
          target.parent?.dropState?.value = DropState.none;
          break;
      }
    }
  }

  void dispose() {
    _target?.dropState?.value = DropState.none;
    _target?.parent?.dropState?.value = DropState.none;
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
  final List<T> _data;

  _TreeDragOperation<T> _dragOperation;

  bool get isDragging => _dragOperation != null;
  _TreeDragOperation get dragOperation => _dragOperation;

  TreeController(this._data) {
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
  List<T> childrenOf(T treeItem);

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

  /// Flatten the structure from a hierarchical tree with parent child
  /// relationships to a linear array with indentation properties. This also
  /// generates metadata for widgets to draw lines connecting the tree and it
  /// generates a key to index lookup which will be used in Flutter's ListView
  /// widget to remap rows when items get expanded and their indices inherently
  /// change.
  void flatten() {
    var flat = <FlatTreeItem<T>>[];
    var context = FlattenedTreeDataContext<T>(_expanded);
    var lookup = HashMap<Key, int>();

    _flatten(context, _data, flat, lookup, [], null);
    _flat = flat;
    _indexLookup = lookup;
    notifyListeners();
  }

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
      FlatTreeItem<T> item, DropState state, List<FlatTreeItem<T>> items) {
    if (item.isDisabled || item.dragDepth != null) {
      return false;
    }
    return true;
  }

  /// Perform the drop operation (re-order items/children).
  void drop(
      FlatTreeItem<T> target, DropState state, List<FlatTreeItem<T>> items);

  /// Called when an item is tapped or clicked on.
  void onTap(FlatTreeItem<T> item);

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

  void startDrag(DragStartDetails details, BuildContext context,
      FlatTreeItem<T> dragStartItem, List<FlatTreeItem<T>> items) {
    //print("OVERLAY ${Overlay.of(context)}"); //.insert(this._overlayEntry);
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
          child: Material(
            type: MaterialType.transparency,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: items
                    .map(
                      (item) => Text(item.data.toString()),
                    )
                    .toList(),
              ),
            ),
          ),
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
    var dropState = target?.dropState?.value;
    var items = _dragOperation.items;

    _dragOperation.dispose();
    _dragOperation = null;
    for (final item in _flat) {
      item?.dragDepth = null;
    }

    if (target != null && dropState != null) {
      drop(target, dropState, items);
    }

    notifyListeners();
  }

  void updateDrag(BuildContext itemContext, DragUpdateDetails details,
      FlatTreeItem<T> draggedItem, TreeStyle style) {
    _dragOperation.offset.value = details.globalPosition;

    RenderBox getBox = itemContext.findRenderObject() as RenderBox;
    var local = getBox.globalToLocal(details.globalPosition);
    var index =
        _flat.indexOf(draggedItem) + (local.dy / style.itemHeight).floor();
    var localOffset = local.dy % style.itemHeight;
    // var pos = localOffset < 10
    //     ? "above"
    //     : localOffset > style.itemHeight - 10 ? "below" : "in";

    var dropTarget = index >= 0 && index < _flat.length ? _flat[index] : null;

    var state = localOffset < 10
        ? DropState.above
        : localOffset > style.itemHeight - 10
            ? DropState.below
            : DropState.into;

    if (dropTarget != null &&
        allowDrop(dropTarget, state, _dragOperation.items)) {
      _dragOperation.dropTarget(dropTarget, state);
    } else {
      _dragOperation.dropTarget(null, null);
    }
  }

  void _flatten(
      FlattenedTreeDataContext<T> context,
      List<T> data,
      List<FlatTreeItem<T>> flat,
      HashMap<Key, int> lookup,
      List<int> depth,
      FlatTreeItem<T> parent) {
    assert(!isDragging);
    if (isDragging) {
      // Don't allow flatten during drag.
      return;
    }
    // int depthIndex = depth.length;
    // depth.add(spacing);

    List<T> childItems;
    if (hasProperties) {
      childItems = [];
      List<T> propertyItems = [];
      for (final item in data) {
        if (isProperty(item)) {
          propertyItems.add(item);
          continue;
        }
        childItems.add(item);
      }
      int length = propertyItems.length;
      int childLength = childItems.length;
      for (int i = 0; i < length; i++) {
        var item = propertyItems[i];
        var spacing = spacingOf(item);
        var itemDepth = childLength == 0 ? depth + [1] : depth + [1, 1];

        var meta = FlatTreeItem<T>(
          item,
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
    for (int i = 0; i < childLength; i++) {
      var isLast = i == childLength - 1;
      var item = childItems[i];
      var spacing = spacingOf(item);
      var isExpanded = context.expanded.contains(item);
      var children = childrenOf(item);
      bool hasChildren = children?.isNotEmpty ?? false;
      var itemDepth = depth + [1];
      var meta = FlatTreeItem<T>(
        item,
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
    }
  }
}
