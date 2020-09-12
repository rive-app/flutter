import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:rive_editor/rive/alerts/simple_alert.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:utilities/restorer.dart';

typedef FilterStageItems = bool Function(StageItem stageItem);

class SelectStageItemHelper {
  SimpleAlert _alert;
  Restorer _selectionRestorer;

  void dismiss() {
    if (_alert != null) {
      _selectionRestorer?.restore();
      // In case the dismiss comes in during a widget build cycle...
      SchedulerBinding.instance.scheduleTask(_alert.dismiss, Priority.touch);
    }
    _alert = null;
  }

  Future<Iterable<StageItem>> show(
      OpenFileContext context, String message, FilterStageItems filter) {
    dismiss();
    context.addAlert(
      _alert = SimpleAlert(message, autoDismiss: false),
    );

    var completer = Completer<Iterable<StageItem>>();

    _selectionRestorer = context.stage.addSelectionHandler(
      (StageItem item) {
        if (filter(item)) {
          completer.complete([item]);
        }
        dismiss();
        return true;
      },
    );
    return completer.future;
  }
}
