import 'package:flutter/foundation.dart';

enum SelectionState { selected, hovered, none }

/// Selection states are also entirely left up to the tree implementation, the
/// tree widget itself assumes nothing regarding selections. We chose to
/// implement it as an interface.
abstract class SelectableItem {
  ValueListenable<SelectionState> get selectionState;
  void select(SelectionState state);
}