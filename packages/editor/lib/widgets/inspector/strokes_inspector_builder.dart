import 'package:flutter/material.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:rive_editor/widgets/common/converters/rotation_value_converter.dart';
import 'package:rive_editor/widgets/common/converters/scale_value_converter.dart';
import 'package:rive_editor/widgets/common/converters/translation_value_converter.dart';
import 'package:rive_editor/widgets/inspector/inspection_set.dart';
import 'package:rive_editor/widgets/inspector/inspector_builder.dart';
import 'package:rive_editor/widgets/inspector/inspector_group.dart';
import 'package:rive_editor/widgets/inspector/properties/property_dual.dart';
import 'package:rive_editor/widgets/inspector/properties/property_single.dart';

/// Inspect fills.
class StrokesInspectorBuilder extends InspectorBuilder with ChangeNotifier {
  bool _isExpanded = false;

  @override
  bool validate(InspectionSet inspecting) =>
      inspecting.intersectingCoreTypes.contains(ShapeBase.typeKey);

  @override
  List<WidgetBuilder> expand(InspectionSet inspecting) {
    return [
      (context) => InspectorGroup(
          name: 'Strokes',
          isExpanded: _isExpanded,
          tapExpand: () {
            _isExpanded = !_isExpanded;
            notifyListeners();
          },
          add: () {
            print('add fill');
          }),
      if (_isExpanded) ...[
        // These aren't the correct property editors, just showing some content
        // and how the expansion works for now.
        (context) => PropertyDual(
              name: 'Position',
              objects: inspecting.components,
              propertyKeyA: NodeBase.xPropertyKey,
              propertyKeyB: NodeBase.yPropertyKey,
              labelA: 'X',
              labelB: 'Y',
              converter: TranslationValueConverter.instance,
            ),
        (context) => PropertyDual(
              name: 'Scale',
              linkable: true,
              objects: inspecting.components,
              propertyKeyA: NodeBase.scaleXPropertyKey,
              propertyKeyB: NodeBase.scaleYPropertyKey,
              labelA: 'X',
              labelB: 'Y',
              converter: ScaleValueConverter.instance,
            ),
        (context) => PropertySingle(
              name: 'Rotate',
              objects: inspecting.components,
              propertyKey: NodeBase.rotationPropertyKey,
              converter: RotationValueConverter.instance,
            ),
      ]
    ];
  }
}
