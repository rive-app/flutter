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

abstract class KeyFrameInterface {
  int get frame;
}

class KeyFrameList<T extends KeyFrameInterface> {
  List<T> _keyframes = [];
  Iterable<T> get keyframes => _keyframes;
  set keyframes(Iterable<T> frames) => _keyframes = frames.toList();

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
        idx = start = mid;
        break;
      }

      idx = start;
    }
    return idx;
  }

  void sort() => _keyframes.sort((a, b) => a.frame.compareTo(b.frame));
}

class KeyedProperty extends KeyedPropertyBase<RiveFile>
    with KeyFrameList<KeyFrame> {
  // -> editor-only
  bool _suppressValidation = false;
  bool get suppressValidation => _suppressValidation;
  set suppressValidation(bool value) {
    if (_suppressValidation == value) {
      return;
    }
    _suppressValidation = value;
    if (!_suppressValidation) {
      _sortAndValidateKeyFrames();
    }
  }
  // <- editor-only

  @override
  void onAdded() {
    if (keyedObjectId != null) {
      KeyedObject keyedObject = context?.resolve(keyedObjectId);
      if (keyedObject == null) {
        _log.finest("Failed to resolve KeyedObject with id $keyedObjectId");
      } else {
        keyedObject.internalAddKeyedProperty(this);
      }
    }
  }

  KeyedObject get keyedObject => context?.resolve(keyedObjectId);

  @override
  void onAddedDirty() {}

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
    if (_keyframes.isEmpty) {
      // Remove this keyed property.
      context.remove(this);
    }
    context?.dirty(_notifyKeyframeRemoved);
    return removed;
  }

  void internalKeyFrameMoved() {
    keyedObject?.internalKeyFramesMoved();
  }

  void internalKeyFrameInterpolationChanged() {
    keyedObject?.internalKeyFramesChanged();
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
    sort();

    // -> editor-only
    if (suppressValidation) {
      keyedObject?.internalKeyFramesChanged();
      return;
    }
    // <- editor-only

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
        idx = start = mid;
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

          /// Equivalent to fromFrame.interpolation ==
          /// KeyFrameInterpolation.hold.
          if (fromFrame.interpolationType == 0) {
            fromFrame.apply(object, pk, mix);
          } else {
            fromFrame.applyInterpolation(object, pk, seconds, toFrame, mix);
          }
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

  /// Should be @internal when supported.
  void internalKeyFrameValueChanged() =>
      keyedObject?.internalKeyFrameValueChanged();
}
