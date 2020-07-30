import 'dart:math';

import 'package:rive_core/animation/keyframe_double.dart';
import 'package:rive_core/animation/linear_animation.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/node.dart';

import 'key_frame.dart';

class KeyFrameRotation extends KeyFrameConverter {
  KeyFrameRotation(num value, int interpolatorType, List interpolatorCurve)
      : super(value, interpolatorType, interpolatorCurve);

  @override
  void convertKey(Component component, LinearAnimation animation, int frame) {
    final radians = (value as num).toDouble() * pi / 180;
    generateKey<KeyFrameDoubleBase>(
        component, animation, frame, NodeBase.rotationPropertyKey)
      ..value = radians;
  }
}
