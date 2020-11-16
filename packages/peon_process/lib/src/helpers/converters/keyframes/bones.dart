import 'package:peon_process/converters.dart';
import 'package:rive_core/animation/keyframe_double.dart';
import 'package:rive_core/bones/bone.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/animation/linear_animation.dart';

class KeyFrameBoneLengthConverter extends KeyFrameConverter {
  KeyFrameBoneLengthConverter(
      num value, int interpolatorType, List interpolatorCurve)
      : super(value, interpolatorType, interpolatorCurve);

  @override
  void convertKey(Component component, LinearAnimation animation, int frame) {
    // TODO: implement convertKey
    if (component is! Bone) {
      throw UnsupportedError(
          'Cannot change length for ${component.runtimeType}');
    }

    generateKey<KeyFrameDouble>(
            component, animation, frame, BoneBase.lengthPropertyKey)
        .value = (value as num).toDouble();
  }
}
