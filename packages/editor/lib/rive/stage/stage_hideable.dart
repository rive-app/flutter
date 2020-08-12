import 'package:core/debounce.dart';

/// Show/hide a stage item based on a boolean value notifier

import 'package:flutter/foundation.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';

class HideableStageItem<T> extends StageItem<T> {
  ValueNotifier<bool> isShownNotifier;
  bool get isHidden => !isShownNotifier.value;
  // Function to call when the item is unhidden; required as the item won't have
  // access to the stage when hidden as the item's been removed
  Function(StageItem) unhideFunc;

  @override
  void addedToStage(Stage stage) {
    _bindNotifier(stage);
    super.addedToStage(stage);
  }

  @override
  void onSelectedChanged(bool value, bool notify) {
    // If the item is selected and hidden, show it
    if (isHidden && value) {
      _unhide();
    }
    // If the item is unselected and marked for hidden, hide it
    if (isHidden && !value) {
      // Needs debouncing as this will trigger the selection to be cleared
      // twice
      debounce(_hide);
    }
    super.onSelectedChanged(value, notify);
  }

  /// Bind the notifier to the stage's notifier
  void _bindNotifier(Stage stage) {
    // if (T == TransformComponent) {
    isShownNotifier = stage.showNodesNotifier;
    isShownNotifier.addListener(_changeHidden);
    // } else {
    //   assert(false, 'Type "$T" is not a supported hideable stage type');
    // }
  }

  void _unhide() {
    if (unhideFunc != null) {
      unhideFunc(this);
    }
    unhideFunc = null;
  }

  void _hide() {
    if (stage != null) {
      // Track the function to call when the items are unhidden
      unhideFunc = stage.unhideItem;
      stage.hideItem(this);
    }
  }

  void _changeHidden() => !isHidden ? _unhide() : _hide();
}
