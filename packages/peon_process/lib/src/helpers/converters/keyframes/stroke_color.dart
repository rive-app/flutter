import 'package:peon_process/converters.dart';
import 'package:rive_core/animation/keyframe_color.dart';
import 'package:rive_core/animation/linear_animation.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/shapes/paint/solid_color.dart';
import 'package:rive_core/shapes/shape_paint_container.dart';

class KeyFrameSolidStrokeConverter extends KeyFrameColorConverter {
  const KeyFrameSolidStrokeConverter(
      List value, int interpolatorType, List interpolatorCurve)
      : assert(value.length == 4),
        super(value, interpolatorType, interpolatorCurve);

  @override
  Component getColorComponent(ShapePaintContainer from) {
    if (from.strokes.isEmpty) {
      print('Leftover stroke in: ${from.runtimeType}');
      return null;
    }
    final stroke = from.strokes.first;
    final strokeComponent = stroke?.children?.first;
    if (strokeComponent is! SolidColorBase) {
      print('Leftover stroke: ${strokeComponent.runtimeType}');
      return null;
    }

    return strokeComponent;
  }

  @override
  void convertKey(Component component, LinearAnimation animation, int frame) {
    if (component is! ShapePaintContainer) {
      throw UnsupportedError('Cannot add fill to ${component.runtimeType}');
    }

    final colorComponent = getColorComponent(component as ShapePaintContainer);

    if (colorComponent == null) {
      return;
    }
    final key = super.generateKey<KeyFrameColor>(
        colorComponent, animation, frame, SolidColorBase.colorValuePropertyKey);
    key.value = getColorValue(value as List);
  }
}
