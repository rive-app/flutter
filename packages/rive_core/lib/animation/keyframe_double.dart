import 'package:core/core.dart';
import 'package:rive_core/animation/keyframe_interpolation.dart';
import 'package:rive_core/src/generated/animation/keyframe_double_base.dart';
import 'package:rive_core/src/generated/rive_core_context.dart';
export 'package:rive_core/src/generated/animation/keyframe_double_base.dart';

class KeyFrameDouble extends KeyFrameDoubleBase {
  @override
  void apply(Core<CoreContext> object, int propertyKey, double mix) {
    RiveCoreContext.animateDouble(object, propertyKey, value * mix);
  }

  @override
  void onAdded() {
    super.onAdded();

    // TODO: Remove this and update keyframe.json to set interpolationType's
    // initialValue to 0 (hold).
    interpolation ??= KeyFrameInterpolation.linear;
  }

  @override
  void applyInterpolation(Core<CoreContext> object, int propertyKey,
      double currentTime, KeyFrameDouble nextFrame, double mix) {
    var f = (currentTime - seconds) / (nextFrame.seconds - seconds);

    if (interpolator != null) {
      f = interpolator.transform(f);
    }

    var interpolatedValue = value + (nextFrame.value - value) * f;

    if (mix == 1) {
      RiveCoreContext.animateDouble(object, propertyKey, interpolatedValue);
    } else {
      var mixi = 1.0 - mix;
      RiveCoreContext.animateDouble(
          object,
          propertyKey,
          RiveCoreContext.getDouble(object, propertyKey) * mixi +
              interpolatedValue * mix);
    }
  }

  // -> editor-only
  @override
  void keyedPropertyIdChanged(Id from, Id to) {}
  // <- editor-only

  @override
  void valueChanged(double from, double to) {
    // -> editor-only
    keyedProperty?.internalKeyFrameValueChanged();
    // <- editor-only
  }

  @override
  void valueFrom(Core object, int propertyKey) {
    value = RiveCoreContext.getDouble(object, propertyKey);
  }
}
