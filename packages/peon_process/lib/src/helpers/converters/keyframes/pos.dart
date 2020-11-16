import 'package:peon_process/converters.dart';
import 'package:rive_core/animation/keyframe_double.dart';
import 'package:rive_core/animation/linear_animation.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/bones/root_bone.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/node.dart';

class KeyFramePosX extends KeyFrameConverter {
  const KeyFramePosX(num value, int interpolatorType, List interpolatorCurve)
      : super(value, interpolatorType, interpolatorCurve);

  int getPropertyKey(Component component) {
    int propertyKey;
    if (component is ArtboardBase) {
      propertyKey = ArtboardBase.xPropertyKey;
    } else if (component is NodeBase) {
      propertyKey = NodeBase.xPropertyKey;
    } else if (component is RootBoneBase) {
      propertyKey = RootBoneBase.xPropertyKey;
    } else {
      throw UnsupportedError(
          'xPropertyKey not found for ${component.runtimeType}');
    }

    return propertyKey;
  }

  @override
  void convertKey(Component component, LinearAnimation animation, int frame) {
    generateKey<KeyFrameDouble>(
        component, animation, frame, getPropertyKey(component))
      .value = (value as num).toDouble();
  }
}

class KeyFramePosY extends KeyFrameConverter {
  const KeyFramePosY(num value, int interpolatorType, List interpolatorCurve)
      : super(value, interpolatorType, interpolatorCurve);

  int getPropertyKey(Component component) {
    int propertyKey;
    if (component is ArtboardBase) {
      propertyKey = ArtboardBase.yPropertyKey;
    } else if (component is NodeBase) {
      propertyKey = NodeBase.yPropertyKey;
    } else if (component is RootBoneBase) {
      propertyKey = RootBoneBase.yPropertyKey;
    } else {
      throw UnsupportedError(
          'yPropertyKey not found for ${component.runtimeType}');
    }

    return propertyKey;
  }

  @override
  void convertKey(Component component, LinearAnimation animation, int frame) {
    generateKey<KeyFrameDouble>(
        component, animation, frame, getPropertyKey(component))
      .value = (value as num).toDouble();
  }
}
