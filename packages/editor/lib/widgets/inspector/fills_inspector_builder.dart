import 'package:flutter/widgets.dart';
import 'package:rive_core/shapes/paint/fill.dart';
import 'package:rive_core/shapes/paint/shape_paint.dart';
import 'package:rive_core/event.dart';
import 'package:rive_core/shapes/shape_paint_container.dart';
import 'package:rive_editor/widgets/inspector/color/inspecting_color.dart';
import 'package:rive_editor/widgets/inspector/properties/property_fill.dart';
import 'package:rive_editor/widgets/inspector/shape_paint_inspector_builder.dart';

/// Inspect fills.
class FillsInspectorBuilder extends ShapePaintInspectorBuilder<Fill> {
  @override
  Event changedEventOf(ShapePaintContainer container) => container.fillsChanged;

  @override
  ShapePaint createFor(ShapePaintContainer container) =>
      container.createGradientFill();

  @override
  String get name => 'Fills';

  @override
  Widget propertyEditorFor(BuildContext context, List<Fill> fills,
          ShapesInspectingColor inspectingColor) =>
      PropertyFill(
        fills: fills,
        inspectingColor: inspectingColor,
      );

  @override
  Set<Fill> shapePaintsOf(ShapePaintContainer container) => container.fills;
}
