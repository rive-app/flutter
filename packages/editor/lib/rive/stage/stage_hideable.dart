/// Show/hide a stage item based on a boolean value notifier

import 'package:flutter/foundation.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';

abstract class HideableStageItem<T> extends StageItem<T> {
  ValueNotifier<bool> get isShownNotifier;
  @override
  bool get isVisible => isShownNotifier.value || hasSelectionFlags;
}
