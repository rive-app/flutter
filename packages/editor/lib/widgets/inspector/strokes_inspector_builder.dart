import 'package:flutter/material.dart';
import 'package:rive_core/shapes/paint/shape_paint.dart';
import 'package:rive_core/event.dart';
import 'package:rive_core/shapes/shape_paint_container.dart';
import 'package:rive_editor/widgets/inspector/color/inspecting_color.dart';
import 'package:rive_editor/widgets/inspector/properties/property_stroke.dart';
import 'package:rive_editor/widgets/inspector/shape_paint_inspector_builder.dart';

/// Inspect fills.
class StrokesInspectorBuilder extends ShapePaintInspectorBuilder {
  @override
  Event changedEventOf(ShapePaintContainer container) =>
      container.strokesChanged;

  @override
  ShapePaint createFor(ShapePaintContainer container) =>
      container.createStroke(const Color(0xFFFFFFFF));

  @override
  String get name => 'Strokes';

  @override
  Widget propertyEditorFor(BuildContext context, List<ShapePaint> shapePaints,
          ShapesInspectingColor inspectingColor) =>
      PropertyStroke(
        strokes: shapePaints,
        inspectingColor: inspectingColor,
      );

  @override
  Set<ShapePaint> shapePaintsOf(ShapePaintContainer container) =>
      container.strokes;
}