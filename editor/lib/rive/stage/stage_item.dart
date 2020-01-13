import 'package:flutter/foundation.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_editor/rive/stage/aabb_tree.dart';

extension StageItemComponent on Component {
  StageItem get stageItem => userData as StageItem;
  set stageItem(StageItem value) => userData = value;
}

abstract class StageItem<T> extends SelectableItem {
  final ValueNotifier<SelectionState> _selectionState =
      ValueNotifier<SelectionState>(SelectionState.none);

  T _object;
  T get object => _object;

  int visTreeProxy = NullNode;

  bool initialize(T object) {
    _object = object;
    return true;
  }

  @override
  ValueListenable<SelectionState> get selectionState => _selectionState;

  @override
  void select(SelectionState state) => _selectionState.value = state;

  /// Provide an aabb for this stage item.
  AABB get aabb;
}
