import 'package:flutter/material.dart';
import 'package:rive_core/transform_component.dart';
import 'package:rive_editor/widgets/inspector/inspection_set.dart';
import 'package:rive_editor/widgets/inspector/inspector_builder.dart';
import 'package:rive_editor/widgets/inspector/inspector_group.dart';
import 'package:rive_editor/widgets/inspector/properties/property_normal_draw.dart';

class InspectDrawOrder extends ListenableInspectorBuilder {
  bool _isExpanded = true;

  void _createDrawTarget(InspectionSet inspecting) {
    var file = inspecting.fileContext.core;
    // file.batchAdd(() {
    //   for (final component in inspecting.components) {
    //     if (component is! TransformComponent || component is core.Path) {
    //       continue;
    //     }

    //     var clipper = ClippingShape();
    //     file.addObject(clipper);
    //     clipper.shape = shape;
    //     (component as TransformComponent).appendChild(clipper);
    //   }
    // });
    file.captureJournalEntry();
  }

  @override
  List<WidgetBuilder> expand(
          BuildContext panelContext, InspectionSet inspecting) =>
      [
        (context) => InspectorGroup(
              name: 'Draw Order',
              isExpanded: _isExpanded,
              tapExpand: () {
                _isExpanded = !_isExpanded;
                notifyListeners();
              },
              add: () {
                _createDrawTarget(inspecting);
              },
            ),
        if (_isExpanded) (context) => const PropertyNormalDraw()
        // for (var clippingShape in _clippableComponent.clippingShapes)
        //   (context) => PropertyClip(clippingShape: clippingShape),
      ];

  @override
  bool validate(InspectionSet inspecting) {
    if (inspecting.components.length != 1) {
      return false;
    }
    var selectedComponent = inspecting.components.first;
    if (selectedComponent is TransformComponent) {
      changeWhen([selectedComponent.drawRulesChanged]);
      return true;
    }
    return false;
  }
}
