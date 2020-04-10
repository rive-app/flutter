import 'dart:ui';

import 'package:rive_core/component_dirt.dart';
import 'package:rive_core/shapes/paint/shape_paint_mutator.dart';
import 'package:rive_core/shapes/shape_paint_container.dart';
import 'package:rive_core/src/generated/shapes/paint/solid_color_base.dart';
export 'package:rive_core/src/generated/shapes/paint/solid_color_base.dart';

/// A solid color painter for a shape. Works for both Fill and Stroke.
class SolidColor extends SolidColorBase with ShapePaintMutator {
  Color get color => Color(colorValue);
  set color(Color c) {
    colorValue = c.value;
  }

  @override
  void colorValueChanged(int from, int to) {
    super.colorValueChanged(from, to);

    // Since all we need to do is set the color on the paint, we can just do
    // this whenever it changes as it's such a lightweight operation. We don't
    // need to schedule it for the next update cycle, which saves us from adding
    // SolidColor to the dependencies graph.
    paint?.color = color;

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
    paint?.color = color;
  }
}
