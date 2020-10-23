import 'package:flutter/foundation.dart';
import 'package:rive_core/event.dart';

enum SelectionState { selected, hovered, none }

class _SelectionFlags {
  static const int selected = 1 << 0;
  static const int hovered = 1 << 1;
}

/// Selection states are also entirely left up to the tree implementation, the
/// tree widget itself assumes nothing regarding selections. We chose to
/// implement it as an interface.
class SelectableItem {
  final _selectionState =
      SuppressableValueNotifier<SelectionState>(SelectionState.none);

  ValueListenable<SelectionState> get selectionState => _selectionState;

  int _selectionFlags = 0;
  void _updateSelectionFlags(bool notify) {
    if (_selectionFlags & _SelectionFlags.selected != 0) {
      _selectionState.changeValue(SelectionState.selected, notify: notify);
    } else if (_selectionFlags & _SelectionFlags.hovered != 0) {
      _selectionState.changeValue(SelectionState.hovered, notify: notify);
    } else {
      _selectionState.changeValue(SelectionState.none, notify: notify);
    }
  }

  void notifySelectionState() {
    _selectionState.notify();
    onSelectedChanged(isSelected, true);
  }

  void onHoverChanged(bool hovered) {}
  void onSelectedChanged(bool selected, bool notify) {}

  /// Returns true if this item is either selected or hovered.
  bool get hasSelectionFlags => _selectionFlags != 0;

  /// Whether this item has a pointer over it.
  bool get isHovered => _selectionFlags & _SelectionFlags.hovered != 0;
  set isHovered(bool value) {
    var flags = _selectionFlags;
    if (value) {
      flags |= _SelectionFlags.hovered;
    } else {
      flags &= ~_SelectionFlags.hovered;
    }
    if (flags != _selectionFlags) {
      _selectionFlags = flags;
      _updateSelectionFlags(true);
      onHoverChanged(value);
    }
  }

  /// Whether this item is part of a selection context.
  bool get isSelected => _selectionFlags & _SelectionFlags.selected != 0;
  set isSelected(bool value) {
    select(value, notify: true);
  }

  /// Change selection value and optionally set whether or not to notify.
  bool select(bool value, {bool notify = true}) {
    var flags = _selectionFlags;
    if (value) {
      flags |= _SelectionFlags.selected;
    } else {
      flags &= ~_SelectionFlags.selected;
    }
    if (flags != _selectionFlags) {
      _selectionFlags = flags;
      _updateSelectionFlags(notify);
      onSelectedChanged(value, notify);
      return true;
    }
    return false;
  }
}
