import 'package:flutter/material.dart';
import 'package:rive_core/event.dart';
import 'package:rive_core/shapes/paint/shape_paint.dart';
import 'package:rive_core/shapes/shape_paint_container.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/inspector/color/inspecting_color.dart';
import 'package:rive_editor/widgets/inspector/inspection_set.dart';
import 'package:rive_editor/widgets/inspector/inspector_builder.dart';
import 'package:rive_editor/widgets/inspector/inspector_group.dart';
import 'package:rive_editor/widgets/inspector/inspector_filters.dart';
import 'package:rive_editor/widgets/inspector/properties/property_shape_paint_text_input.dart';
import 'package:utilities/list_equality.dart';

/// Inspect fills/strokes.
abstract class ShapePaintInspectorBuilder<T extends ShapePaint>
    extends ListenableInspectorBuilder {
  bool _isExpanded = true;

  // We build and store a cache of inspecting colors as multiple inspector rows
  // use these and they're relatively expensive as they operate on sets of sets.
  final List<ShapesInspectingColor> _inspectingColors = [];

  Event changedEventOf(ShapePaintContainer container);
  Set<T> shapePaintsOf(ShapePaintContainer container);
  String get name;
  ShapePaint createFor(ShapePaintContainer container);
  Widget propertyEditorFor(BuildContext context, List<T> shapePaints,
      ShapesInspectingColor inspectingColor);

  @override
  List<WidgetBuilder> expand(
      BuildContext panelContext, InspectionSet inspecting) {
    var shapes = inspecting.components.whereType<ShapePaintContainer>();

    // Rebuild whenever the fills/strokes are changed on any of our shapes.
    changeWhen(shapes.map(changedEventOf));

    // We're guaranteed that the number of fills/strokes is the same, so we can
    // transpose the set and edit each Nth list of fills/strokes as one unique
    // value (if they're not the same the editor will handle that condition and
    // allow the user to set them all to the same fill/stroke).
    var listOfCommonPaints = shapes.transpose(shapePaintsOf);

    var widgets = <WidgetBuilder>[
      (context) => InspectorGroup(
          name: name,
          isExpanded: _isExpanded,
          tapExpand: () {
            _isExpanded = !_isExpanded;
            notifyListeners();
          },
          add: () => _createShapePaint(ActiveFile.of(context), inspecting)),
    ];

    if (_isExpanded) {
      // We iterate in reverse as designers expect these in reverse order as
      // opposed to how we store them: https://github.com/rive-app/rive/issues/173
      var paintsInDisplayOrder =
          listOfCommonPaints.reversed.toList(growable: false);
      for (int i = 0, l = paintsInDisplayOrder.length; i < l; i++) {
        var shapePaints = paintsInDisplayOrder[i];
        ShapesInspectingColor inspectingColor;
        if (i < _inspectingColors.length) {
          inspectingColor = _inspectingColors[i];
          // When the fills/strokes in the inspecting color match the current
          // ones, we can keep using it. Otherwise we need to build up a new
          // inspecting color.
          if (!iterableEquals(shapePaints, inspectingColor.shapePaints)) {
            // Need a new inspecting color as the shapes changed, but let's
            // propagate the settings in case it was being edited.
            var replacement = ShapesInspectingColor(shapePaints);
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
          inspectingColor = ShapesInspectingColor(shapePaints);
          _inspectingColors.add(inspectingColor);
        }
        widgets.add((context) =>
            propertyEditorFor(context, shapePaints, inspectingColor));
        widgets.add(
          (context) => PropertyShapePaintTextInput(
            shapePaints: shapePaints,
            inspectingColor: inspectingColor,
          ),
        );
      }

      // Cleanup any remaining color inspectors that are no longer necessary.
      while (_inspectingColors.length > listOfCommonPaints.length) {
        _inspectingColors.removeLast().dispose();
      }
    }
    return widgets;
  }

  @override
  bool validate(InspectionSet inspecting) {
    // Only interested in ShapeContainers...
    // ...with the same number of strokes/fills.
    if (!inspecting.components
        .every((component) => component is ShapePaintContainer)) {
      return false;
    }
    var isValid = inspecting.components
        .whereType<ShapePaintContainer>()
        .allSame((component) => shapePaintsOf(component).length,
            isEmptySame: false);

    if (!isValid) {
      // cleanup the cached inspecting colors.
      for (final inspectingColor in _inspectingColors) {
        inspectingColor.dispose();
      }
      _inspectingColors.clear();
    }
    return isValid;
  }

  @protected
  void _createShapePaint(OpenFileContext file, InspectionSet inspecting) {
    // Create shape paints for objects in our inspection set that are shape
    // paint containers.
    var core = file.core;

    var shapePaintContainers =
        inspecting.components.whereType<ShapePaintContainer>();

    // Early out if there are none (shouldn't really ever happen, but some race
    // condition may cause this).
    if (shapePaintContainers.isEmpty) {
      return;
    }
    core.batchAdd(() {
      shapePaintContainers.forEach(createFor);
    });
    core.captureJournalEntry();
  }
}
