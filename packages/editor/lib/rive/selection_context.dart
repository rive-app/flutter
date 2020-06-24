import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:rive_editor/selectable_item.dart';

/// Manages a list of selected items. Allows selecting and deselecting new
/// items.
class SelectionContext<T extends SelectableItem> extends ChangeNotifier {
  final Set<T> _items = {};
  Set<T> get items => _items;
  T get first => _items.first;
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;

  final HashSet<T> _notifyDeselect = HashSet<T>();

  void clear({bool notify = true}) {
    if (!notify) {
      _notifyDeselect.addAll(_items);
    }
    for (final prev in _items) {
      prev.select(false, notify: notify);
    }
    _items.clear();
    if (notify) {
      notifyListeners();
    }
  }

  /// Select multiple items. Specify whether to [append] them to the current
  /// selection and whether to [notify] any listenables of the change. If you
  /// choose to suppress notification you can later notify by calling
  /// [notifySelection].
  void selectMultiple(
    Iterable<T> items, {
    bool append = false,
    bool notify = true,
  }) {
    if (!append) {
      clear(notify: false);
    }
    _items.addAll(items);
    for (final item in _items) {
      item.select(true, notify: notify);
    }
    if (notify) {
      notifyListeners();
    }
  }

  void notifySelection() {
    _notifyDeselect.addAll(_items);
    var items = _notifyDeselect.toList(growable: false);
    _notifyDeselect.clear();

    for (final item in items) {
      item.notifySelectionState();
    }
    notifyListeners();
  }

  bool select(T item, {bool append = false, bool notify = true}) {
    assert(item != null, 'should not select a null item');
    if (!append) {
      clear(notify: false);
    }
    if (_items.add(item)) {
      item.select(true, notify: notify);
      if (notify) {
        notifySelection();
      }
      return true;
    }
    return false;
  }

  bool deselect(T item, {bool notify = true}) {
    assert(item != null);
    if (_items.remove(item)) {
      item.select(false, notify: notify);
      if (notify) {
        notifySelection();
      } else {
        _notifyDeselect.add(item);
      }
      return true;
    }
    return false;
  }
}
