import 'package:core/core.dart';
import 'package:rive_core/animation/keyframe_draw_order.dart';
import 'package:rive_core/animation/keyframe_draw_order_value.dart';
import 'package:rive_core/animation/keyframe_interpolation.dart';
import 'package:rive_core/animation/linear_animation.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/drawable.dart';

import 'key_frame.dart';

class KeyFrameDrawOrderConverter extends KeyFrameConverter {
  const KeyFrameDrawOrderConverter(
      num value, int interpolatorType, List interpolatorCurve)
      : super(value, interpolatorType, interpolatorCurve);

  @override
  void convertKey(Component component, LinearAnimation animation, int frame) {
    // Draw Order is keyed to the Artboard.
    final artboard = component.artboard;
    final key = generateKey<KeyFrameDrawOrder>(
        artboard, animation, frame, DrawableBase.drawOrderPropertyKey);

    final numValue = value as num;

    // TODO:
    // make sure that this makes sense, and it doesn't need an
    // extra pre-processing step.
    final drawOrderValue = KeyFrameDrawOrderValue()
      ..drawableId = component.id
      ..value = FractionalIndex(numValue, numValue + 1);
    key.internalAddValue(drawOrderValue);
    key.interpolation = KeyFrameInterpolation.hold;
  }
}
