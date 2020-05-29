import 'package:flutter/foundation.dart';

enum SelectionState { selected, hovered, none }

class _SelectionFlags {
  static const int selected = 1 << 0;
  static const int hovered = 1 << 1;
  static const int none = 0;
}

/// Selection states are also entirely left up to the tree implementation, the
/// tree widget itself assumes nothing regarding selections. We chose to
/// implement it as an interface.
abstract class SelectableItem {
  final _selectionState = ValueNotifier<SelectionState>(SelectionState.none);

  ValueListenable<SelectionState> get selectionState => _selectionState;

  int _selectionFlags = 0;
  void _updateSelectionFlags() {
    if (_selectionFlags & _SelectionFlags.selected != 0) {
      _selectionState.value = SelectionState.selected;
    } else if (_selectionFlags & _SelectionFlags.hovered != 0) {
      _selectionState.value = SelectionState.hovered;
    } else {
      _selectionState.value = SelectionState.none;
    }
  }

  void onHoverChanged(bool hovered) {}
  void onSelectedChanged(bool selected) {}

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
      _updateSelectionFlags();
      onHoverChanged(value);
    }
  }

  /// Whether this item is part of a selection context.
  bool get isSelected => _selectionFlags & _SelectionFlags.selected != 0;
  set isSelected(bool value) {
    var flags = _selectionFlags;
    if (value) {
      flags |= _SelectionFlags.selected;
    } else {
      flags &= ~_SelectionFlags.selected;
    }
    if (flags != _selectionFlags) {
      _selectionFlags = flags;
      _updateSelectionFlags();
      onSelectedChanged(value);
    }
  }
}
