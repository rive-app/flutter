import 'package:core/core.dart' as core;
import 'package:core/core.dart';
import 'package:logging/logging.dart';
import 'package:rive_core/animation/interpolator.dart';
import 'package:rive_core/animation/keyed_property.dart';
import 'package:rive_core/animation/keyframe_interpolation.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/src/generated/animation/keyframe_base.dart';
export 'package:rive_core/src/generated/animation/keyframe_base.dart';

final _log = Logger('animation');

abstract class KeyFrame extends KeyFrameBase<RiveFile>
    implements KeyFrameInterface {
  double _timeInSeconds;
  double get seconds => _timeInSeconds;

  KeyFrameInterpolation get interpolation => interpolationType == null
      ? null
      : KeyFrameInterpolation.values[interpolationType];
  set interpolation(KeyFrameInterpolation value) {
    interpolationType = value.index;
  }

  @override
  void interpolationTypeChanged(int from, int to) {
    keyedProperty?.internalKeyFrameInterpolationChanged();
  }

  @override
  void interpolatorIdChanged(core.Id from, core.Id to) {
    // This might resolve to null during a load or if context isn't available
    // yet so we also do this in onAddedDirty.
    interpolator = context?.resolve(to);
  }

  @override
  void onAdded() {
    if (keyedPropertyId != null) {
      KeyedProperty keyedProperty = context?.resolve(keyedPropertyId);
      if (keyedProperty == null) {
        _log.finest("Failed to resolve KeyedProperty with id $keyedPropertyId");
      } else {
        keyedProperty.internalAddKeyFrame(this);
      }
    }
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
    if (interpolatorId != null) {
      interpolator = context?.resolve(interpolatorId);
      if (interpolator == null) {
        _log.finest("Failed to resolve interpolator with id $interpolatorId");
      }
    }
  }

  @override
  void onRemoved() {
    keyedProperty?.internalRemoveKeyFrame(this);
    _interpolator?.propertiesChanged
        ?.removeListener(_interpolatorPropertyChanged);
  }

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

  Interpolator _interpolator;
  Interpolator get interpolator => _interpolator;
  set interpolator(Interpolator value) {
    if (_interpolator == value) {
      return;
    }
    // -> editor-only
    _interpolator?.propertiesChanged
        ?.removeListener(_interpolatorPropertyChanged);
    value?.propertiesChanged?.addListener(_interpolatorPropertyChanged);
    // <- editor-only
    _interpolator = value;
    interpolatorId = value?.id;
    keyedProperty?.internalKeyFrameInterpolationChanged();
  }

  // -> editor-only
  void _interpolatorPropertyChanged() {
    keyedProperty?.internalKeyFrameInterpolationChanged();
  }
  // <- editor-only
}
