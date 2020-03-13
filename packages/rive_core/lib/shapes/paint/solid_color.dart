import 'dart:ui';

import 'package:rive_core/shapes/paint/shape_paint_mutator.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:rive_core/src/generated/shapes/paint/solid_color_base.dart';
export 'package:rive_core/src/generated/shapes/paint/solid_color_base.dart';

/// A solid color painter for a shape. Works for both Fill and Stroke.
class SolidColor extends SolidColorBase with ShapePaintMutator {
  Color _color;
  Color get color => _color;
  set color(Color c) {
    colorValue = c.value;
  }

  SolidColor() {
    _color = Color(colorValue);
  }

  @override
  void colorValueChanged(int from, int to) {
    super.colorValueChanged(from, to);

    _color = Color(to);

    // Since all we need to do is set the color on the paint, we can just do
    // this whenever it changes as it's such a lightweight operation. We don't
    // need to schedule it for the next update cycle, which saves us from adding
    // SolidColor to the dependencies graph.
    paint?.color = _color;
  }

  @override
  void update(int dirt) {
    // Intentionally empty. SolidColor doesn't need an update cycle and doesn't
    // depend on anything.
  }

  @override
  void initializePaintMutator(Shape shape, Paint paint) {
    super.initializePaintMutator(shape, paint);
    paint?.color = _color;
  }
}
