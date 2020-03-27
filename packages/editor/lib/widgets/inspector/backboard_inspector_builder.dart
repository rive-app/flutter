import 'package:flutter/material.dart';
import 'package:rive_core/backboard.dart';
import 'package:rive_editor/widgets/inspector/inspection_set.dart';
import 'package:rive_editor/widgets/inspector/inspector_builder.dart';
import 'package:rive_editor/widgets/inspector/properties/property_color.dart';

/// Returns the inspector for Artboard selections.
class BackboardInspectorBuilder extends ListenableInspectorBuilder {
  @override
  bool validate(InspectionSet inspecting) =>
      inspecting.stageItems.isEmpty && inspecting.backboard != null;

  @override
  List<WidgetBuilder> expand(InspectionSet inspecting) => [
        (context) => PropertyColor(
              name: 'Background',
              objects: [inspecting.backboard],
              propertyKey: BackboardBase.colorValuePropertyKey,
            ),
      ];
}
