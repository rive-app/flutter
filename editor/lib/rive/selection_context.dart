import 'package:flutter/material.dart';
import 'package:rive_core/selectable_item.dart';

/// Manages a list of selected items. Allows selecting and deselecting new
/// items.
class SelectionContext<T extends SelectableItem> extends ChangeNotifier {
  final Set<T> _items = {};
  Set<T> get items => _items;
  T get first => _items.first;
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;

  void clear({bool notify = true}) {
    for (final prev in _items) {
      prev.isSelected = false;
    }
    _items.clear();
    if (notify) {
      notifyListeners();
    }
  }

  void selectMultiple(Iterable<T> items, {bool append = false}) {
    if (!append) {
      clear(notify: false);
    }
    _items.addAll(items);
    for (final item in _items) {
      item.isSelected = true;
    }
    notifyListeners();
  }

  bool select(T item, {bool append = false}) {
    assert(item != null);
    if (!append) {
      clear(notify: false);
    }
    if (_items.add(item)) {
      item.isSelected = true;
      notifyListeners();
      return true;
    }
    return false;
  }
}
