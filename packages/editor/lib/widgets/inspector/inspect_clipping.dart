import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:rive_core/transform_component.dart';
import 'package:rive_core/shapes/path.dart' as core;
import 'package:rive_editor/rive/alerts/simple_alert.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/widgets/inspector/inspection_set.dart';
import 'package:rive_editor/widgets/inspector/inspector_builder.dart';
import 'package:rive_editor/widgets/inspector/inspector_group.dart';

/// Example inspector builder with combo boxes.
class InspectClipping extends ListenableInspectorBuilder {
  bool _isExpanded = true;
  SimpleAlert _pickClippingAlert;
  Stage _handlerStage;

  void _dismissAlert() {
    if (_pickClippingAlert != null) {
      _handlerStage.removeSelectionHandler(_selectionHandler);
      SchedulerBinding.instance
          .scheduleTask(_pickClippingAlert.dismiss, Priority.touch);
    }
    _pickClippingAlert = null;
  }

  @override
  void clean() {
    _dismissAlert();
  }

  bool _selectionHandler(StageItem item) {
    if (item.component is Shape) {
      print("USE THIS SHAPE: ${item.component}");
    }
    _dismissAlert();
    return true;
  }

  @override
  List<WidgetBuilder> expand(InspectionSet inspecting) => [
        (context) => InspectorGroup(
              name: 'CLIPPING',
              isExpanded: _isExpanded,
              tapExpand: () {
                _isExpanded = !_isExpanded;
                notifyListeners();
              },
              add: () {
                _dismissAlert();
                inspecting.fileContext.addAlert(_pickClippingAlert =
                    SimpleAlert('Pick a shape to use as a clipping source.',
                        autoDismiss: false));
                _handlerStage = inspecting.stage;
                _handlerStage.addSelectionHandler(_selectionHandler);
              },
            ),
      ];

  @override
  bool validate(InspectionSet inspecting) => inspecting.components
      .any((item) => item is TransformComponent && item is! core.Path);
}
