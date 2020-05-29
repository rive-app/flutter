import 'dart:ui';
import 'package:rive/rive_core/component_dirt.dart';
import 'package:rive/rive_core/shapes/paint/shape_paint_mutator.dart';
import 'package:rive/rive_core/shapes/shape_paint_container.dart';
import 'package:rive/src/generated/shapes/paint/solid_color_base.dart';
export 'package:rive/src/generated/shapes/paint/solid_color_base.dart';

class SolidColor extends SolidColorBase with ShapePaintMutator {
  Color get color => Color(colorValue);
  set color(Color c) {
    colorValue = c.value;
  }

  @override
  void colorValueChanged(int from, int to) {
    paint?.color = color;
    shapePaintContainer?.addDirt(ComponentDirt.paint);
  }

  @override
  void update(int dirt) {}
  @override
  void initializePaintMutator(ShapePaintContainer paintContainer, Paint paint) {
    super.initializePaintMutator(paintContainer, paint);
    paint?.color = color;
  }
}
