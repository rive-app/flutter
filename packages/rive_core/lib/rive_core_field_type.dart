import 'package:core/field_types/core_double_type.dart';
import 'package:rive_core/animation/keyframe.dart';
import 'package:rive_core/animation/keyframe_double.dart';

abstract class KeyFrameGenerator<T extends KeyFrame> {
  T makeKeyFrame();
}

class RiveDoubleType extends CoreDoubleType
    implements KeyFrameGenerator<KeyFrameDouble> {
  @override
  KeyFrameDouble makeKeyFrame() => KeyFrameDouble();

  RiveDoubleType._constructor();
  static RiveDoubleType instance = RiveDoubleType._constructor();
}
