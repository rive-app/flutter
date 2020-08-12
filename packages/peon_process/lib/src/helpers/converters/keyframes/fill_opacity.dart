import 'package:peon_process/converters.dart';
import 'package:rive_core/animation/keyframe_double.dart';
import 'package:rive_core/animation/linear_animation.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/shapes/paint/linear_gradient.dart';
import 'package:rive_core/shapes/paint/solid_color.dart';
import 'package:rive_core/shapes/shape_paint_container.dart';
import 'package:rive_core/transform_component.dart';

class KeyFrameFillOpacityConverter extends KeyFrameConverter {
  const KeyFrameFillOpacityConverter(
      num value, int interpolatorType, List interpolatorCurve)
      : super(value, interpolatorType, interpolatorCurve);

  @override
  void convertKey(Component component, LinearAnimation animation, int frame) {
    if (component is! ShapePaintContainer) {
      throw UnsupportedError('Cannot add opacity to ${component.runtimeType}');
    }

    final fill = (component as ShapePaintContainer).fills.first;
    final colorComponent = fill.children.first;

    // Opacity KeyFrame for solid colors is on the shape,
    // but for gradients it is applied to the gradient itself.
    if (colorComponent is SolidColorBase) {
      generateKey<KeyFrameDouble>(component, animation, frame,
          TransformComponentBase.opacityPropertyKey)
        ..value = (value as num).toDouble();
    } else if (colorComponent is LinearGradientBase) {
      generateKey<KeyFrameDouble>(colorComponent, animation, frame,
          LinearGradientBase.opacityPropertyKey)
        ..value = (value as num).toDouble();
    }
  }
}
