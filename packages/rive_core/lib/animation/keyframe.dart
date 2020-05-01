import 'package:core/core.dart' as core;
import 'package:logging/logging.dart';
import 'package:rive_core/animation/keyed_property.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/src/generated/animation/keyframe_base.dart';
export 'package:rive_core/src/generated/animation/keyframe_base.dart';

final _log = Logger('animation');

abstract class KeyFrame extends KeyFrameBase<RiveFile>
    implements KeyFrameInterface {
  double _timeInSeconds;
  double get seconds => _timeInSeconds;

  @override
  void onAdded() {
    _updateSeconds();
  }

  void _updateSeconds() {
    var property = keyedProperty;
    if (property?.keyedObject?.animation == null) {
      return;
    }
    _timeInSeconds = frame / property.keyedObject.animation.fps;
    property.internalKeyFrameMoved();
  }

  KeyedProperty get keyedProperty => context?.resolve(keyedPropertyId);

  @override
  void onAddedDirty() {
    if (keyedPropertyId != null) {
      KeyedProperty keyedProperty = context?.resolve(keyedPropertyId);
      if (keyedProperty == null) {
        _log.finest("Failed to resolve KeyedProperty with id $keyedPropertyId");
      } else {
        keyedProperty.internalAddKeyFrame(this);
      }
    }
  }

  @override
  void onRemoved() => keyedProperty?.internalRemoveKeyFrame(this);

  @override
  void frameChanged(int from, int to) {
    keyedProperty?.markKeyFrameOrderDirty();
    _updateSeconds();
  }

  /// Apply the value of this keyframe to the object's property.
  void apply(core.Core object, int propertyKey, double mix);

  /// Interpolate the value between this keyframe and the next and apply it to
  /// the object's property.
  void applyInterpolation(core.Core object, int propertyKey, double seconds,
      covariant KeyFrame nextFrame, double mix);

  /// Set the value of this keyframe to the current value of [object]'s
  /// [propertyKey].
  void valueFrom(core.Core object, int propertyKey);
}
