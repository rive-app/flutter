import 'dart:collection';

import 'package:core/core.dart';
import 'package:rive_core/animation/keyed_object.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/src/generated/animation/animation_base.dart';
export 'package:rive_core/src/generated/animation/animation_base.dart';

class Animation extends AnimationBase<RiveFile> {
  /// Map objectId to KeyedObject. N.B. this is the id of the object that we
  /// want to key in core, not of the KeyedObject. It's a clear way to see if an
  /// object is keyed in this animation.
  final HashMap<Id, KeyedObject> _keyedObjects = HashMap<Id, KeyedObject>();

  @override
  void onAdded() {
    // TODO: implement onAdded
  }

  @override
  void onAddedDirty() {
    // TODO: implement onAddedDirty
  }

  @override
  void onRemoved() {
    // TODO: implement onRemoved
  }

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
  void apply(double time, {double mix = 1, RiveFile coreContext}) {
    coreContext ??= context;
    for (final keyedObject in _keyedObjects.values) {
      keyedObject.apply(time, mix, coreContext);
    }
  }
}
