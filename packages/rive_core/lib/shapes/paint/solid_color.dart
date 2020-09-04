import 'dart:ui';

import 'package:rive_core/component.dart';
import 'package:rive_core/component_dirt.dart';
import 'package:rive_core/shapes/paint/shape_paint.dart';
import 'package:rive_core/shapes/paint/shape_paint_mutator.dart';
import 'package:rive_core/shapes/shape_paint_container.dart';
import 'package:rive_core/src/generated/shapes/paint/solid_color_base.dart';
export 'package:rive_core/src/generated/shapes/paint/solid_color_base.dart';

/// A solid color painter for a shape. Works for both Fill and Stroke.
class SolidColor extends SolidColorBase with ShapePaintMutator {
  // -> editor-only
  @override
  Component get timelineProxy => parent;
  // <- editor-only

  Color get color => Color(colorValue);
  set color(Color c) {
    colorValue = c.value;
  }

  @override
  void colorValueChanged(int from, int to) {
    // Since all we need to do is set the color on the paint, we can just do
    // this whenever it changes as it's such a lightweight operation. We don't
    // need to schedule it for the next update cycle, which saves us from adding
    // SolidColor to the dependencies graph.
    syncColor();

    // Since we're not in the dependency tree, chuck dirt onto the shape, which
    // is. This just ensures we'll paint as soon as possible to show the updated
    // color.
    shapePaintContainer?.addDirt(ComponentDirt.paint);
  }

  @override
  void update(int dirt) {
    // Intentionally empty. SolidColor doesn't need an update cycle and doesn't
    // depend on anything.
  }

  @override
  void initializePaintMutator(ShapePaintContainer paintContainer, Paint paint) {
    super.initializePaintMutator(paintContainer, paint);
    syncColor();
  }

  @override
  void syncColor() {
    paint?.color = color
        .withOpacity((color.opacity * renderOpacity).clamp(0, 1).toDouble());
  }

  // -> editor-only
  @override
  bool validate() {
    return super.validate() && parent is ShapePaint;
  }
  // <- editor-only
}
