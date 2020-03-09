import 'package:flutter/material.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:rive_editor/widgets/inspector/inspection_set.dart';
import 'package:rive_editor/widgets/inspector/inspector_builder.dart';
import 'package:rive_editor/widgets/inspector/inspector_group.dart';
import 'package:rive_editor/widgets/inspector/properties/property_dual.dart';
import 'package:rive_editor/widgets/inspector/properties/property_single.dart';

/// Inspect fills.
class FillsInspectorBuilder extends InspectorBuilder with ChangeNotifier {
  bool _isExpanded = false;

  @override
  bool validate(InspectionSet inspecting) =>
      inspecting.intersectingCoreTypes.contains(ShapeBase.typeKey);

  @override
  List<WidgetBuilder> expand(InspectionSet inspecting) {
    return [
      (context) => InspectorGroup(
            name: 'Fills',
            isExpanded: _isExpanded,
            tapExpand: () {
              _isExpanded = !_isExpanded;
              notifyListeners();
            },
            add: () {
              print('add fill');
            }
          ),
      if (_isExpanded) ...[
        (context) => PropertyDual(
              name: 'Position',
              objects: inspecting.components,
              propertyKeyA: NodeBase.xPropertyKey,
              propertyKeyB: NodeBase.yPropertyKey,
              labelA: 'X',
              labelB: 'Y',
            ),
        (context) => PropertyDual(
              name: 'Scale',
              linkable: true,
              objects: inspecting.components,
              propertyKeyA: NodeBase.scaleXPropertyKey,
              propertyKeyB: NodeBase.scaleYPropertyKey,
              labelA: 'X',
              labelB: 'Y',
            ),
        (context) => PropertySingle(
              name: 'Rotate',
              objects: inspecting.components,
              propertyKey: NodeBase.rotationPropertyKey,
            ),
      ]
    ];
  }
}