import 'package:rive_core/selectable_item.dart';

/// Manages a list of selected items. Allows selecting and deselecting new
/// items.
class SelectionContext<T extends SelectableItem> {
  final Set<T> _items = {};
  Set<T> get items => _items;

  void clear() {
    for (final prev in _items) {
      prev.isSelected = false;
    }
    _items.clear();
  }

  void selectMultiple(Iterable<T> items, {bool append = false}) {
    if (!append) {
      clear();
    }
    _items.addAll(items);
    for (final item in _items) {
      item.isSelected = true;
    }
  }

  bool select(T item, {bool append = false}) {
    assert(item != null);
    if (!append) {
      clear();
    }
    if (_items.add(item)) {
      item.isSelected = true;
      return true;
    }
    return false;
  }
}
