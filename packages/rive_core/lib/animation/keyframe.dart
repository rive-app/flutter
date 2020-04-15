import 'package:core/core.dart' as core;
import 'package:rive_core/animation/keyed_property.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/src/generated/animation/keyframe_base.dart';
export 'package:rive_core/src/generated/animation/keyframe_base.dart';

abstract class KeyFrame extends KeyFrameBase<RiveFile> {
  @override
  void onAdded() {}

  KeyedProperty get keyedProperty => context?.resolve(keyedPropertyId);

  @override
  void onAddedDirty() {
    if (keyedPropertyId != null) {
      KeyedProperty keyedProperty = context?.resolve(keyedPropertyId);
      if (keyedProperty == null) {
        log.finest("Failed to resolve KeyedProperty with id $keyedPropertyId");
      } else {
        keyedProperty.internalAddKeyFrame(this);
      }
    }
  }

  @override
  void onRemoved() => keyedProperty?.internalRemoveKeyFrame(this);

  @override
  void timeChanged(int from, int to) {
    keyedProperty?.markKeyFrameOrderDirty();
    super.timeChanged(from, to);
  }

  /// Apply the value of this keyframe to the object's property.
  void apply(core.Core object, int propertyKey, double mix);

  /// Interpolate the value between this keyframe and the next and apply it to
  /// the object's property.
  void applyInterpolation(core.Core object, int propertyKey, int time,
      covariant KeyFrame nextFrame, double mix);
}
