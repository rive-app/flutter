import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:rive_editor/selectable_item.dart';
import 'package:utilities/restorer.dart';

typedef SelectionHandler<T extends SelectableItem> = bool Function(T);

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
      item.select(true, notify: false);
    }
    if (notify) {
      notifySelection();
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

  bool isCustomHandled(T item) {
    // See if a handler wants to swallow this event...
    for (final handler in _handlers) {
      if (handler.call(item)) {
        return true;
      }
    }
    return false;
  }

  bool select(
    T item, {
    bool append = false,
    bool notify = true,
    bool skipHandlers = false,
  }) {
    assert(item != null, 'should not select a null item');

    // See if a handler wants to swallow this select...
    if (!skipHandlers && isCustomHandled(item)) {
      return false;
    }

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

  final Set<SelectionHandler<T>> _handlers = {};

  Restorer addHandler(SelectionHandler<T> handler) {
    assert(!_handlers.contains(handler));
    if (_handlers.add(handler)) {
      return _SelectionHandlerRestorer(handler, this);
    }
    return null;
  }

  bool _removeHandler(SelectionHandler<T> handler) => _handlers.remove(handler);
}

class _SelectionHandlerRestorer<T extends SelectableItem> implements Restorer {
  final SelectionHandler<T> _handler;
  SelectionContext<T> _context;

  _SelectionHandlerRestorer(this._handler, this._context);

  @override
  bool restore() {
    var removed = _context?._removeHandler(_handler) ?? false;
    _context = null;
    return removed;
  }
}
