import 'package:peon_process/converters.dart';
import 'package:rive_core/animation/keyframe_double.dart';
import 'package:rive_core/animation/linear_animation.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/shapes/paint/stroke.dart';
import 'package:rive_core/shapes/shape_paint_container.dart';

class KeyFrameStrokeWidthConverter extends KeyFrameConverter {
  const KeyFrameStrokeWidthConverter(
      num value, int interpolatorType, List interpolatorCurve)
      : super(value, interpolatorType, interpolatorCurve);

  @override
  void convertKey(Component component, LinearAnimation animation, int frame) {
    if (component is! ShapePaintContainer) {
      throw UnsupportedError('Cannot add fill to ${component.runtimeType}');
    }

    final strokeComponent = (component as ShapePaintContainer).strokes.first;

    generateKey<KeyFrameDouble>(
        strokeComponent, animation, frame, StrokeBase.thicknessPropertyKey)
      ..value = (value as num).toDouble();
  }
}
