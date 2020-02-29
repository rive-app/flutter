import 'package:flutter/material.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_editor/widgets/inspector/inspection_set.dart';
import 'package:rive_editor/widgets/inspector/inspector_builder.dart';
import 'package:rive_editor/widgets/inspector/properties/property_dual.dart';

/// Returns the inspector for Artboard selections.
class ArtboardInspectorBuilder extends InspectorBuilder {
  @override
  bool validate(InspectionSet inspecting) =>
      inspecting.intersectingCoreTypes.contains(ArtboardBase.typeKey);

  @override
  List<WidgetBuilder> expand(InspectionSet inspecting) => [
        (context) => PropertyDual(
              name: 'Position',
              objects: inspecting.components,
              propertyKeyA: ArtboardBase.xPropertyKey,
              propertyKeyB: ArtboardBase.yPropertyKey,
              labelA: 'X',
              labelB: 'Y',
            ),
        (context) => PropertyDual(
              name: 'Size',
              linkable: true,
              objects: inspecting.components,
              propertyKeyA: ArtboardBase.widthPropertyKey,
              propertyKeyB: ArtboardBase.heightPropertyKey,
              labelA: 'Width',
              labelB: 'Height',
            ),
        (context) => PropertyDual(
              name: 'Origin',
              linkable: true,
              objects: inspecting.components,
              propertyKeyA: ArtboardBase.originXPropertyKey,
              propertyKeyB: ArtboardBase.originYPropertyKey,
              labelA: 'X',
              labelB: 'Y',
            )
      ];
}
