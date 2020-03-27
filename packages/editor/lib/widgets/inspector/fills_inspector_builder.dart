import 'package:flutter/material.dart';
import 'package:rive_core/shapes/paint/fill.dart';
import 'package:rive_core/shapes/paint/solid_color.dart';
import 'package:rive_core/shapes/shape_paint_container.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/inspector/inspection_set.dart';
import 'package:rive_editor/widgets/inspector/inspector_builder.dart';
import 'package:rive_editor/widgets/inspector/inspector_group.dart';
import 'package:rive_editor/widgets/inspector/inspector_filters.dart';
import 'package:rive_editor/widgets/inspector/properties/property_fill.dart';

/// Inspect fills.
class FillsInspectorBuilder extends ListenableInspectorBuilder {
  bool _isExpanded = true;

  @override
  List<WidgetBuilder> expand(InspectionSet inspecting) {
    var shapes = inspecting.components.whereType<ShapePaintContainer>();

    // Rebuild whenever the fills are changed on any of our shapes.
    changeWhen(shapes.map((shape) => shape.fillsChanged));

    return [
      (context) => InspectorGroup(
          name: 'Fills',
          isExpanded: _isExpanded,
          tapExpand: () {
            _isExpanded = !_isExpanded;
            notifyListeners();
          },
          add: () => _createFill(RiveContext.of(context), inspecting)),
      if (_isExpanded) ...[
        // We're guaranteed that the number of fills is the same, so we can
        // transpose the set and edit each Nth list of Fills as one unique value
        // (if they're not the same the editor will handle that condition and
        // allow the user to set them all to the same fill).
        for (final fills in shapes.transpose((shape) => shape.fills))
          (context) => PropertyFill(fills: fills)
      ]
    ];
  }

  @override
  bool validate(InspectionSet inspecting) =>
      // Only interested in ShapeContainers...
      // ...with the same number of fills.
      inspecting.components
          .whereType<ShapePaintContainer>()
          .allSame((component) => component.fills.length, isEmptySame: false);

  void _createFill(Rive rive, InspectionSet inspecting) {
    // We know these are all shapes, so we can iterate them and add a new fill
    // to each one. Let's do it in a batch operation.
    var file = rive.file.value;

    file.batchAdd(() {
      for (final component in inspecting.components) {
        var shape = component as ShapePaintContainer;
        var fill = Fill()..name = 'Fill ${shape.fills.length + 1}';
        var solidColor = SolidColor()..color = const Color(0xFFFF5678);

        file.add(fill);
        file.add(solidColor);

        fill.appendChild(solidColor);
        shape.appendChild(fill);
      }
    });
    file.captureJournalEntry();
  }
}
