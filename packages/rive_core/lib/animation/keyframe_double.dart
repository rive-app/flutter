import 'package:core/core.dart';
import 'package:rive_core/src/generated/animation/keyframe_double_base.dart';
import 'package:rive_core/src/generated/rive_core_context.dart';
export 'package:rive_core/src/generated/animation/keyframe_double_base.dart';

class KeyFrameDouble extends KeyFrameDoubleBase {
  @override
  void apply(Core<CoreContext> object, int propertyKey, double mix) {
    RiveCoreContext.setDouble(object, propertyKey, value * mix);
  }

  @override
  void applyInterpolation(Core<CoreContext> object, int propertyKey,
      int currentTime, KeyFrameDouble nextFrame, double mix) {
    var f = (currentTime - time) / (nextFrame.time - time);

    var fi = 1 - f;
    var interpolatedValue = value * fi + nextFrame.value * f;

    if (mix == 1) {
      RiveCoreContext.setDouble(object, propertyKey, interpolatedValue);
    } else {
      var mixi = 1.0 - mix;
      RiveCoreContext.setDouble(
          object,
          propertyKey,
          RiveCoreContext.getDouble(object, propertyKey) * mixi +
              interpolatedValue * mix);
    }
  }
}
