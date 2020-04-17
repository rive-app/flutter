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
      double currentTime, KeyFrameDouble nextFrame, double mix) {
    var f = (currentTime - seconds) / (nextFrame.seconds - seconds);

    var interpolatedValue = value + (nextFrame.value - value) * f;

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

  @override
  void interpolationChanged(int from, int to) {}

  @override
  void interpolatorIdChanged(Id from, Id to) {}

  @override
  void keyedPropertyIdChanged(Id from, Id to) {}

  @override
  void valueChanged(double from, double to) {}
}
