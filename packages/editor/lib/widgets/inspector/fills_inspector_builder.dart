import 'package:flutter/material.dart';
import 'package:rive_core/shapes/shape_paint_container.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/inspector/color/inspecting_color.dart';
import 'package:rive_editor/widgets/inspector/inspection_set.dart';
import 'package:rive_editor/widgets/inspector/inspector_builder.dart';
import 'package:rive_editor/widgets/inspector/inspector_group.dart';
import 'package:rive_editor/widgets/inspector/inspector_filters.dart';
import 'package:rive_editor/widgets/inspector/properties/property_fill.dart';
import 'package:rive_editor/widgets/inspector/properties/property_shape_paint_text_input.dart';
import 'package:utilities/list_equality.dart';

/// Inspect fills.
class FillsInspectorBuilder extends ListenableInspectorBuilder {
  bool _isExpanded = true;

  // We build and store a cache of inspecting colors as multiple inspector rows
  // use these and they're relatively expensive as they operate on sets of sets.
  final List<ShapesInspectingColor> _inspectingColors = [];

  @override
  List<WidgetBuilder> expand(InspectionSet inspecting) {
    var shapes = inspecting.components.whereType<ShapePaintContainer>();

    // Rebuild whenever the fills are changed on any of our shapes.
    changeWhen(shapes.map((shape) => shape.fillsChanged));

    // We're guaranteed that the number of fills is the same, so we can
    // transpose the set and edit each Nth list of Fills as one unique value (if
    // they're not the same the editor will handle that condition and allow the
    // user to set them all to the same fill).
    var listOfCommonFills = shapes.transpose((shape) => shape.fills);

    var widgets = <WidgetBuilder>[
      (context) => InspectorGroup(
          name: 'Fills',
          isExpanded: _isExpanded,
          tapExpand: () {
            _isExpanded = !_isExpanded;
            notifyListeners();
          },
          add: () => _createFill(ActiveFile.of(context), inspecting)),
    ];

    if (_isExpanded) {
      // We iterate in reverse as designers expect these in reverse order as
      // opposed to how we store them: https://github.com/rive-app/rive/issues/173
      for (int i = listOfCommonFills.length - 1; i >= 0; i--) {
        var fills = listOfCommonFills[i];
        ShapesInspectingColor inspectingColor;
        if (i < _inspectingColors.length) {
          inspectingColor = _inspectingColors[i];
          // When the fills in the inspecting color match the current ones, we
          // can keep using it. Otherwise we need to build up a new inspecting
          // color.
          if (!iterableEquals(fills, inspectingColor.shapePaints)) {
            // Need a new inspecting color as the shapes changed, but let's
            // propagate the settings in case it was being edited.
            var replacement = ShapesInspectingColor(fills);
            if (inspectingColor.isEditing) {
              replacement.startEditing(inspectingColor.context);
            }
            inspectingColor.dispose();
            inspectingColor = replacement;
            // Cache it so we can re-use it if we re-expand this.
            _inspectingColors[i] = inspectingColor;
          }
        } else {
          // No inspecting color, make a new one.
          inspectingColor = ShapesInspectingColor(fills);
          _inspectingColors.add(inspectingColor);
        }
        widgets.add(
          (context) => PropertyFill(
            fills: fills,
            inspectingColor: inspectingColor,
          ),
        );
        widgets.add(
          (context) => PropertyShapePaintTextInput(
            shapePaints: fills,
            inspectingColor: inspectingColor,
          ),
        );
      }

      // Cleanup any remaining color inspectors that are no longer necessary.
      while (_inspectingColors.length > listOfCommonFills.length) {
        _inspectingColors.removeLast().dispose();
      }
    }
    return widgets;
  }

  @override
  bool validate(InspectionSet inspecting) {
    // Only interested in ShapeContainers...
    // ...with the same number of fills.
    var isValid = inspecting.components
        .whereType<ShapePaintContainer>()
        .allSame((component) => component.fills.length, isEmptySame: false);

    if (!isValid) {
      // cleanup the cached inspecting colors.
      for (final inspectingColor in _inspectingColors) {
        inspectingColor.dispose();
      }
      _inspectingColors.clear();
    }
    return isValid;
  }

  void _createFill(OpenFileContext file, InspectionSet inspecting) {
    // We know these are all shapes, so we can iterate them and add a new fill
    // to each one. Let's do it in a batch operation.
    var core = file.core;

    core.batchAdd(() {
      for (final component in inspecting.components) {
        (component as ShapePaintContainer).createFill(const Color(0xFFFF5678));
      }
    });
    core.captureJournalEntry();
  }
}
