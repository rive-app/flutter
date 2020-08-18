import 'package:flutter/foundation.dart';
import 'package:peon_process/converters.dart';
import 'package:rive_core/animation/keyframe.dart';
import 'package:rive_core/animation/keyframe_interpolation.dart';
import 'package:rive_core/animation/linear_animation.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/shapes/shape_paint_container.dart';

abstract class KeyFrameConverter {
  const KeyFrameConverter(
      this.value, this.interpolatorType, this.interpolatorCurve);

  final Object value;
  final int interpolatorType;
  final List interpolatorCurve;

  void convertKey(Component component, LinearAnimation animation, int frame);

  // Adds the keyframe, and gets the reference to it.
  // Overrides provide the type annotation for the key frame.
  @protected
  T generateKey<T extends KeyFrame>(Component component,
      LinearAnimation animation, int frame, int propertyKey) {
    final key = component.addKeyFrame<T>(animation, propertyKey, frame);
    setInterpolation(key, animation.context);
    return key;
  }

  @protected
  void setInterpolation(KeyFrame keyFrame, RiveFile context) {
    keyFrame.interpolation =
        InterpolatorConverter.getInterpolator(interpolatorType);
    if (keyFrame.interpolation == KeyFrameInterpolation.cubic) {
      final cubicInterpolator =
          InterpolatorConverter.cubicFrom(interpolatorCurve);
      context.addObject(cubicInterpolator);
      keyFrame.interpolator = cubicInterpolator;
    }
  }
}

abstract class KeyFrameColorConverter extends KeyFrameConverter {
  const KeyFrameColorConverter(
      Object value, int interpolatorType, List interpolatorCurve)
      : super(value, interpolatorType, interpolatorCurve);

  Component getColorComponent(ShapePaintContainer from);

  @protected
  int getColorValue(List rgba) {
    /** Shamelessy stolen from [Color].
     * Same as:
    return Color.fromRGBO(
      (rgba[0] * 255).toInt(),
      (rgba[1] * 255).toInt(),
      (rgba[2] * 255).toInt(),
      rgba[3].toDouble(),
    ).value;
    * just bypassing the extra object.
    */
    final a = (rgba[3] as num).toDouble();
    final r = ((rgba[0] as num) * 255).toInt();
    final g = ((rgba[1] as num) * 255).toInt();
    final b = ((rgba[2] as num) * 255).toInt();

    return ((((a * 0xff ~/ 1) & 0xff) << 24) |
            ((r & 0xff) << 16) |
            ((g & 0xff) << 8) |
            ((b & 0xff) << 0)) &
        0xFFFFFFFF;
  }
}
