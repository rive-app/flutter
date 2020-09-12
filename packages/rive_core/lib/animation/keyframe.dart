import 'package:core/core.dart';
import 'package:logging/logging.dart';
import 'package:rive_core/animation/interpolator.dart';
import 'package:rive_core/animation/keyed_property.dart';
import 'package:rive_core/animation/keyframe_interpolation.dart';
import 'package:rive_core/animation/linear_animation.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/src/generated/animation/keyframe_base.dart';

export 'package:rive_core/src/generated/animation/keyframe_base.dart';

// -> editor-only
final _log = Logger('animation');
// <- editor-only

abstract class KeyFrame extends KeyFrameBase<RiveFile>
    implements KeyFrameInterface {
  double _timeInSeconds;
  double get seconds => _timeInSeconds;

  bool get canInterpolate => true;

  KeyFrameInterpolation get interpolation => interpolationType == null
      ? null
      : KeyFrameInterpolation.values[interpolationType];
  set interpolation(KeyFrameInterpolation value) {
    interpolationType = value.index;
  }

  @override
  void interpolationTypeChanged(int from, int to) {
    // -> editor-only
    keyedProperty?.internalKeyFrameInterpolationChanged();
    // <- editor-only
  }

  @override
  void interpolatorIdChanged(Id from, Id to) {
    // This might resolve to null during a load or if context isn't available
    // yet so we also do this in onAddedDirty.
    interpolator = context?.resolve(to);
  }

  @override
  void onAdded() {
    // -> editor-only
    _updateSeconds();
    // <- editor-only
  }

  // -> editor-only
  void _updateSeconds() {
    var property = keyedProperty;
    if (property?.keyedObject?.animation == null) {
      return;
    }
    computeSeconds(property.keyedObject.animation);
    property.internalKeyFrameMoved();
  }
  // <- editor-only

  void computeSeconds(LinearAnimation animation) {
    _timeInSeconds = frame / animation.fps;
  }

  // -> editor-only
  KeyedProperty get keyedProperty => context?.resolve(keyedPropertyId);
  // <- editor-only

  @override
  void onAddedDirty() {
    // -> editor-only
    if (keyedPropertyId != null) {
      // Make sure we resolve keyed properties during dirty cycle so they don't
      // get removed if they are empty (keyed properties should know what they
      // contain by the time dirt is cleaned).
      KeyedProperty keyedProperty = context?.resolve(keyedPropertyId);
      if (keyedProperty == null) {
        _log.finest('Failed to resolve KeyedProperty with id $keyedPropertyId');
      } else {
        keyedProperty.internalAddKeyFrame(this);
      }
    }
    // <- editor-only
    if (interpolatorId != null) {
      interpolator = context?.resolve(interpolatorId);
      // -> editor-only
      if (interpolator == null) {
        _log.finest('Failed to resolve interpolator with id $interpolatorId');
      }
      // <- editor-only
    }
  }

  @override
  void onRemoved() {
    // -> editor-only
    keyedProperty?.internalRemoveKeyFrame(this);
    _interpolator?.propertiesChanged
        ?.removeListener(_interpolatorPropertyChanged);
    // <- editor-only
  }

  @override
  void frameChanged(int from, int to) {
    // -> editor-only
    keyedProperty?.markKeyFrameOrderDirty();
    _updateSeconds();
    // <- editor-only
  }

  /// Apply the value of this keyframe to the object's property.
  void apply(Core object, int propertyKey, double mix);

  /// Interpolate the value between this keyframe and the next and apply it to
  /// the object's property.
  void applyInterpolation(Core object, int propertyKey, double seconds,
      covariant KeyFrame nextFrame, double mix);

  // -> editor-only
  /// Set the value of this keyframe to the current value of [object]'s
  /// [propertyKey].
  void valueFrom(covariant Core object, int propertyKey);
  // <- editor-only

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
    // -> editor-only
    keyedProperty?.internalKeyFrameInterpolationChanged();
    // <- editor-only
  }

  // -> editor-only
  void _interpolatorPropertyChanged() {
    keyedProperty?.internalKeyFrameInterpolationChanged();
  }

  void internalValueChanged() {
    keyedProperty?.internalKeyFrameValueChanged();
  }
  // <- editor-only
}
