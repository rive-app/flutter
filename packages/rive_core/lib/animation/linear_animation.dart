import 'dart:collection';

import 'package:core/core.dart';
import 'package:flutter/widgets.dart';
import 'package:rive_core/animation/keyed_object.dart';
import 'package:rive_core/animation/loop.dart';
import 'package:rive_core/event.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/src/generated/animation/linear_animation_base.dart';
export 'package:rive_core/src/generated/animation/linear_animation_base.dart';

class LinearAnimation extends LinearAnimationBase {
  final Event _keyframesChanged = Event();
  final Event _keyframeValueChanged = Event();

  Listenable get keyframesChanged => _keyframesChanged;
  Listenable get keyframeValueChanged => _keyframeValueChanged;

  int _lastFrame = 0;

  /// The last frame with a keyframe on it.
  int get lastFrame => _lastFrame;

  /// Map objectId to KeyedObject. N.B. this is the id of the object that we
  /// want to key in core, not of the KeyedObject. It's a clear way to see if an
  /// object is keyed in this animation.
  final HashMap<Id, KeyedObject> _keyedObjects = HashMap<Id, KeyedObject>();

  /// The metadata for the objects that are keyed in this animation.
  Iterable<KeyedObject> get keyedObjects => _keyedObjects.values;

  /// Called by rive_core to add a KeyedObject to the animation. This should be
  /// @internal when it's supported.
  bool internalAddKeyedObject(KeyedObject object) {
    assert(
        object.objectId != null,
        'KeyedObject must be referencing a Core object '
        'before being added to an animation.');
    var value = _keyedObjects[object.objectId];

    // If the object is already keyed, that's ok just make sure the KeyedObject
    // matches.
    if (value != null) {
      assert(
          value == object,
          'Trying to add a KeyedObject for an object'
          'that\'s already keyed in this Animation?!');
      return false;
    }
    _keyedObjects[object.objectId] = object;
    return true;
  }

  /// Called by rive_core to remove a KeyedObject from the animation. This
  /// should be @internal when it's supported.
  bool internalRemoveKeyedObject(KeyedObject object) {
    var removed = _keyedObjects.remove(object.objectId);
    if (removed != null) {
      internalKeyFramesChanged();
    }
    assert(removed == null || removed == object);
    return removed != null;
  }

  /// Get the keyed data for a Core object already in this animation.
  KeyedObject getKeyed(Core object) => _keyedObjects[object.id];

  /// Add a core object to this animation and make the objects necessary to key
  /// it. Expects that the object is not yet keyed. Use [getKeyed] to see if
  /// it's already keyed.
  KeyedObject makeKeyed(Core object) {
    assert(getKeyed(object) == null,
        'Object should not already be keyed in this animation.');
    assert(object.id != null, 'Object should already be added to Core.');
    assert(context != null && id != null,
        'Animation should already be added to Core.');

    var keyedObject = KeyedObject()
      ..objectId = object.id
      ..animationId = id;

    context.add(keyedObject);

    // We also add it here in case we're doing a batch add (onAddedDirty will be
    // called later for the keyedObject).
    internalAddKeyedObject(keyedObject);

    // However, we can make sure that it is there.
    assert(getKeyed(object) == keyedObject);

    return keyedObject;
  }

  /// Pass in a different [core] context if you want to apply the animation to a
  /// different instance. This isn't meant to be used yet but left as mostly a
  /// note to remember that at runtime we have to support applying animtaions to
  /// instances. We do a nice job of not duping all that data at runtime (so
  /// animations exist once but entire Rive file can be instanced multiple times
  /// playing different positions).
  void apply(double time, {double mix = 1, RiveCoreContext coreContext}) {
    coreContext ??= context;
    for (final keyedObject in _keyedObjects.values) {
      keyedObject.apply(time, mix, coreContext);
    }
  }

  Loop get loop => Loop.values[loopValue];
  set loop(Loop value) => loopValue = value.index;

  @override
  void durationChanged(int from, int to) {}

  @override
  void enableWorkAreaChanged(bool from, bool to) {}

  @override
  void fpsChanged(int from, int to) {}

  @override
  void loopValueChanged(int from, int to) {}

  @override
  void speedChanged(double from, double to) {}

  @override
  void workEndChanged(int from, int to) {}

  @override
  void workStartChanged(int from, int to) {}


  /// Should be @internal when supported.
  void internalKeyFramesChanged() {
    _computeLastKeyFrameTime();
    _keyframesChanged.notify();
  }

  /// Should be @internal when supported.
  void internalKeyFrameValueChanged() => _keyframeValueChanged.notify();

  void _computeLastKeyFrameTime() {
    _lastFrame = 0;
    for (final property in _keyedObjects.values) {
      if (property.lastFrame > _lastFrame) {
        _lastFrame = property.lastFrame;
      }
    }
  }
}
