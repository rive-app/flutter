import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/shapes/clipping_shape.dart';
import 'package:rive_core/transform_component.dart';
import 'package:rive_core/shapes/path.dart' as core;
import 'package:rive_editor/rive/alerts/simple_alert.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/widgets/inspector/inspection_set.dart';
import 'package:rive_editor/widgets/inspector/inspector_builder.dart';
import 'package:rive_editor/widgets/inspector/inspector_group.dart';
import 'package:rive_editor/widgets/inspector/properties/property_clip.dart';
import 'package:utilities/restorer.dart';

/// Example inspector builder with combo boxes.
class InspectClipping extends ListenableInspectorBuilder {
  bool _isExpanded = true;
  SimpleAlert _pickClippingAlert;
  Restorer _selectionHandlerRestorer;
  TransformComponent _clippableComponent;

  void _dismissAlert() {
    if (_pickClippingAlert != null) {
      _selectionHandlerRestorer?.restore();
      SchedulerBinding.instance
          .scheduleTask(_pickClippingAlert.dismiss, Priority.touch);
    }
    _pickClippingAlert = null;
  }

  @override
  void clean() {
    _dismissAlert();
  }

  void _createClipper(InspectionSet inspecting, Node source) {
    var file = inspecting.fileContext.core;
    file.batchAdd(() {
      for (final component in inspecting.components) {
        if (component is! TransformComponent || component is core.Path) {
          continue;
        }

        var clipper = ClippingShape();
        file.addObject(clipper);
        clipper.source = source;
        (component as TransformComponent).appendChild(clipper);
      }
    });
    file.captureJournalEntry();
  }

  @override
  List<WidgetBuilder> expand(
          BuildContext panelContext, InspectionSet inspecting) =>
      [
        (context) => InspectorGroup(
              name: 'Clipping',
              isExpanded: _isExpanded,
              tapExpand: () {
                _isExpanded = !_isExpanded;
                notifyListeners();
              },
              add: () {
                _dismissAlert();
                inspecting.fileContext.addAlert(
                  _pickClippingAlert = SimpleAlert(
                      'Pick a shape to use as a clipping source.',
                      autoDismiss: false),
                );

                _selectionHandlerRestorer =
                    inspecting.stage.addSelectionHandler(
                  (StageItem item) {
                    if (item.component is Node) {
                      _createClipper(inspecting, item.component as Node);
                    }
                    _dismissAlert();
                    return true;
                  },
                );
              },
            ),
        if (_isExpanded && _clippableComponent.clippingShapes != null)
          for (var clippingShape in _clippableComponent.clippingShapes)
            (context) => PropertyClip(clippingShape: clippingShape),
      ];

  @override
  bool validate(InspectionSet inspecting) {
    if (inspecting.components.length != 1) {
      return false;
    }
    var selectedComponent = inspecting.components.first;
    if (selectedComponent is TransformComponent &&
        selectedComponent is! core.Path) {
          
      _clippableComponent = selectedComponent;

      changeWhen([_clippableComponent.clippingShapesChanged]);
      return true;
    }
    return false;
  }
}
