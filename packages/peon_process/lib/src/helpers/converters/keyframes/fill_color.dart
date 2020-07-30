import 'package:rive_core/animation/keyframe_color.dart';
import 'package:rive_core/animation/linear_animation.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/shapes/paint/solid_color.dart';
import 'package:rive_core/shapes/shape_paint_container.dart';

import 'key_frame.dart';

class KeyFrameSolidColorConverter extends KeyFrameColorConverter {
  const KeyFrameSolidColorConverter(
      List value, int interpolatorType, List interpolatorCurve)
      : super(value, interpolatorType, interpolatorCurve);

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
    key.value = getColorValue(value);
  }

  @override
  Component getColorComponent(ShapePaintContainer from) {
    final fill = from.fills.first;
    final fillComponent = fill.children.first;
    if (fillComponent is! SolidColorBase) {
      print("Leftover fillComponent? ${fillComponent.runtimeType}");
      return null;
    }

    return fillComponent;
  }
}
