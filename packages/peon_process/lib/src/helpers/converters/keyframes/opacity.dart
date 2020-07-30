import 'package:rive_core/animation/keyframe_double.dart';
import 'package:rive_core/animation/linear_animation.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/node.dart';

import 'key_frame.dart';

class KeyFrameOpacity extends KeyFrameConverter {
  const KeyFrameOpacity(num value, int interpolatorType, List interpolatorCurve)
      : super(value, interpolatorType, interpolatorCurve);

  @override
  void convertKey(Component component, LinearAnimation animation, int frame) {
    generateKey<KeyFrameDoubleBase>(
        component, animation, frame, NodeBase.opacityPropertyKey)
      ..value = (value as num).toDouble();
  }
}
