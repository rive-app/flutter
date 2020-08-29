import 'package:flutter/widgets.dart';
import 'package:rive_core/shapes/paint/shape_paint.dart';
import 'package:rive_core/event.dart';
import 'package:rive_core/shapes/paint/stroke.dart';
import 'package:rive_core/shapes/shape_paint_container.dart';
import 'package:rive_editor/widgets/inspector/color/inspecting_color.dart';
import 'package:rive_editor/widgets/inspector/properties/property_stroke.dart';
import 'package:rive_editor/widgets/inspector/shape_paint_inspector_builder.dart';

/// Inspect fills.
class StrokesInspectorBuilder extends ShapePaintInspectorBuilder<Stroke> {
  @override
  Event changedEventOf(ShapePaintContainer container) =>
      container.strokesChanged;

  @override
  ShapePaint createFor(ShapePaintContainer container) =>
      container.createStroke(const Color(0xFFFFFFFF));

  @override
  String get name => 'Strokes';

  @override
  Widget propertyEditorFor(BuildContext context, List<Stroke> strokes,
          ShapesInspectingColor inspectingColor) =>
      PropertyStroke(
        strokes: strokes,
        inspectingColor: inspectingColor,
      );

  @override
  Set<Stroke> shapePaintsOf(ShapePaintContainer container) => container.strokes;
}
