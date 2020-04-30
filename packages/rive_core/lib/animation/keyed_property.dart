import 'package:core/core.dart';
import 'package:core/key_state.dart';
import 'package:logging/logging.dart';
import 'package:rive_core/animation/keyed_object.dart';
import 'package:rive_core/animation/keyframe.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/src/generated/animation/keyed_property_base.dart';
import 'package:rive_core/src/generated/rive_core_context.dart';
export 'package:rive_core/src/generated/animation/keyed_property_base.dart';

final _log = Logger('animation');

class KeyedProperty extends KeyedPropertyBase<RiveFile> {
  final List<KeyFrame> _keyframes = [];

  Iterable<KeyFrame> get keyframes => _keyframes;

  @override
  void onAdded() {}

  KeyedObject get keyedObject => context?.resolve(keyedObjectId);

  @override
  void onAddedDirty() {
    if (keyedObjectId != null) {
      KeyedObject keyedObject = context?.resolve(keyedObjectId);
      if (keyedObject == null) {
        _log.finest("Failed to resolve KeyedObject with id $keyedObjectId");
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
    markKeyFrameOrderDirty();
    return true;
  }

  /// Called by rive_core to remove a KeyFrame from this KeyedProperty. This
  /// should be @internal when it's supported.
  bool internalRemoveKeyFrame(KeyFrame frame) {
    var removed = _keyframes.remove(frame);
    context?.dirty(_notifyKeyframeRemoved);
    return removed;
  }

  void _notifyKeyframeRemoved() {
    keyedObject?.internalKeyFramesChanged();
  }

  /// Called by keyframes when their time value changes. This is a pretty rare
  /// operation, usually occurs when a user moves a keyframe. Meaning: this
  /// shouldn't make it into the runtimes unless we want to allow users moving
  /// keyframes around at runtime via code for some reason.
  void markKeyFrameOrderDirty() {
    context?.dirty(_sortAndValidateKeyFrames);
  }

  void _sortAndValidateKeyFrames() {
    _keyframes.sort((a, b) => a.frame.compareTo(b.frame));
    for (int i = 0; i < _keyframes.length - 1; i++) {
      var a = _keyframes[i];
      var b = _keyframes[i + 1];
      if (a.frame == b.frame) {
        // N.B. this removes it from the list too.
        context.remove(a);
        // Repeat current.
        i--;
      }
    }

    keyedObject?.internalKeyFramesChanged();
  }

  /// Find the index in the keyframe list of a specific time frame.
  int indexOfFrame(int frame) {
    int idx = 0;
    // Binary find the keyframe index.
    int mid = 0;
    int closestFrame = 0;
    int start = 0;
    int end = _keyframes.length - 1;

    while (start <= end) {
      mid = (start + end) >> 1;
      closestFrame = _keyframes[mid].frame;
      if (closestFrame < frame) {
        start = mid + 1;
      } else if (closestFrame > frame) {
        end = mid - 1;
      } else {
        start = mid;
        break;
      }

      idx = start;
    }
    return idx;
  }

  /// Number of keyframes for this keyed property.
  int get numFrames => _keyframes.length;

  KeyFrame getFrameAt(int index) => _keyframes[index];

  void apply(double seconds, double mix, Core object) {
    if (_keyframes.isEmpty) {
      return;
    }

    int idx = 0;
    // Binary find the keyframe index (use timeInSeconds here as opposed to the
    // finder above which operates in frames).
    int mid = 0;
    double closestSeconds = 0;
    int start = 0;
    int end = _keyframes.length - 1;

    while (start <= end) {
      mid = (start + end) >> 1;
      closestSeconds = _keyframes[mid].seconds;
      if (closestSeconds < seconds) {
        start = mid + 1;
      } else if (closestSeconds > seconds) {
        end = mid - 1;
      } else {
        start = mid;
        break;
      }
      idx = start;
    }

    int pk = propertyKey;
    if (idx == 0) {
      var first = _keyframes[0];
      RiveCoreContext.setKeyState(object, pk,
          first.seconds == seconds ? KeyState.keyframe : KeyState.interpolated);
      first.apply(object, pk, mix);
    } else {
      if (idx < _keyframes.length) {
        KeyFrame fromFrame = _keyframes[idx - 1];
        KeyFrame toFrame = _keyframes[idx];
        if (seconds == toFrame.seconds) {
          RiveCoreContext.setKeyState(object, pk, KeyState.keyframe);
          toFrame.apply(object, pk, mix);
        } else {
          RiveCoreContext.setKeyState(object, pk, KeyState.interpolated);
          fromFrame.applyInterpolation(object, pk, seconds, toFrame, mix);
        }
      } else {
        var last = _keyframes[idx - 1];
        RiveCoreContext.setKeyState(
            object,
            pk,
            last.seconds == seconds
                ? KeyState.keyframe
                : KeyState.interpolated);
        last.apply(object, pk, mix);
      }
    }
  }

  @override
  void keyedObjectIdChanged(Id from, Id to) {}

  @override
  void propertyKeyChanged(int from, int to) {}
}
