import 'package:core/core.dart';
import 'package:rive_core/animation/keyframe_interpolation.dart';
import 'package:rive_core/src/generated/animation/keyframe_id_base.dart';
import 'package:rive_core/src/generated/rive_core_context.dart';
export 'package:rive_core/src/generated/animation/keyframe_id_base.dart';

class KeyFrameId extends KeyFrameIdBase {
  @override
  bool get canInterpolate => false;

  @override
  void apply(Core<CoreContext> object, int propertyKey, double mix) {
    RiveCoreContext.animateId(object, propertyKey, value);
  }

  @override
  void onAdded() {
    super.onAdded();

    interpolation ??= KeyFrameInterpolation.hold;
  }

  @override
  void applyInterpolation(Core<CoreContext> object, int propertyKey,
      double currentTime, KeyFrameId nextFrame, double mix) {
    RiveCoreContext.animateId(object, propertyKey, value);
  }

  // -> editor-only
  @override
  void keyedPropertyIdChanged(Id from, Id to) {}
  // <- editor-only

  @override
  void valueChanged(Id from, Id to) {
    // -> editor-only
    internalValueChanged();
    // <- editor-only
  }

  // -> editor-only
  @override
  void valueFrom(Core object, int propertyKey) {
    value = RiveCoreContext.getId(object, propertyKey);
  }
  // <- editor-only
}
