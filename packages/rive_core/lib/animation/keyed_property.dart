import 'package:core/core.dart' as core;
import 'package:rive_core/animation/keyed_object.dart';
import 'package:rive_core/animation/keyframe.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/src/generated/animation/keyed_property_base.dart';
export 'package:rive_core/src/generated/animation/keyed_property_base.dart';

class KeyedProperty extends KeyedPropertyBase<RiveFile> {
  final List<KeyFrame> _keyframes = [];

  /// TODO: consider making this a bitfield if we start marking more things
  /// filthy.
  bool _keyframeOrderDirty = false;

  @override
  void onAdded() {}

  KeyedObject get keyedObject => context?.resolve(keyedObjectId);

  @override
  void onAddedDirty() {
    if (keyedObjectId != null) {
      KeyedObject keyedObject = context?.resolve(keyedObjectId);
      if (keyedObject == null) {
        log.finest("Failed to resolve KeyedObject with id $keyedObjectId");
      } else {
        keyedObject.internalAddKeyedProperty(this);
      }
    }
  }

  @override
  void onRemoved() => keyedObject?.internalRemoveKeyedProperty(this);

  /// Called by rive_core to add a KeyFrame to this KeyedProperty. This should
  /// be @internal when it's supported.
  bool internalAddKeyFrame(KeyFrame frame) {
    if (_keyframes.contains(frame)) {
      return false;
    }
    _keyframes.add(frame);
    return true;
  }

  /// Called by rive_core to remove a KeyFrame from this KeyedProperty. This
  /// should be @internal when it's supported.
  bool internalRemoveKeyFrame(KeyFrame frame) => _keyframes.remove(frame);

  /// Called by keyframes when their time value changes. This is a pretty rare
  /// operation, usually occurs when a user moves a keyframe. Meaning: this
  /// shouldn't make it into the runtimes unless we want to allow users moving
  /// keyframes around at runtime via code for some reason.
  void markKeyFrameOrderDirty() {
    _keyframeOrderDirty = true;
  }

  void apply(int time, double mix, core.Core object) {
    if (_keyframes.isEmpty) {
      return;
    }
    if (_keyframeOrderDirty) {
      _keyframes.sort((a, b) => a.time.compareTo(b.time));
      _keyframeOrderDirty = false;
    }

    int idx = 0;
    // Binary find the keyframe index.
    {
      int mid = 0;
      int closestTime = 0;
      int start = 0;
      int end = _keyframes.length - 1;

      while (start <= end) {
        mid = (start + end) >> 1;
        closestTime = _keyframes[mid].time;
        if (closestTime < time) {
          start = mid + 1;
        } else if (closestTime > time) {
          end = mid - 1;
        } else {
          start = mid;
          break;
        }
      }

      idx = start;
    }

    int pk = propertyKey;
    if (idx == 0) {
      _keyframes[0].apply(object, pk, mix);
    } else {
      if (idx < _keyframes.length) {
        KeyFrame fromFrame = _keyframes[idx - 1];
        KeyFrame toFrame = _keyframes[idx];
        if (time == toFrame.time) {
          toFrame.apply(object, pk, mix);
        } else {
          fromFrame.applyInterpolation(object, pk, time, toFrame, mix);
        }
      } else {
        _keyframes[idx - 1].apply(object, pk, mix);
      }
    }
  }
}
