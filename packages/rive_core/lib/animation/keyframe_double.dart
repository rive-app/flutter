import 'package:rive_core/animation/keyframe.dart';
import 'package:core/core.dart';
import 'package:rive_core/src/generated/animation/keyframe_double_base.dart';
export 'package:rive_core/src/generated/animation/keyframe_double_base.dart';

class KeyFrameDouble extends KeyFrameDoubleBase {
  @override
  void apply(Core<CoreContext> object, int propertyKey, double mix) {
    
  }

  @override
  void applyInterpolation(Core<CoreContext> object, int propertyKey, int time,
      KeyFrame nextFrame, double mix) {}
}
