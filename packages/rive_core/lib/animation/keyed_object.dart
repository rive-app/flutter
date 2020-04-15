import 'dart:collection';

import 'package:core/core.dart' as core;
import 'package:rive_core/animation/animation.dart';
import 'package:rive_core/animation/keyed_property.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/src/generated/animation/keyed_object_base.dart';
export 'package:rive_core/src/generated/animation/keyed_object_base.dart';

class KeyedObject extends KeyedObjectBase<RiveFile> {
  final HashMap<int, KeyedProperty> _keyedProperties =
      HashMap<int, KeyedProperty>();

  @override
  void onAdded() {}

  Animation get animation => context?.resolve(animationId);

  @override
  void onAddedDirty() {
    if (animationId != null) {
      Animation animation = context?.resolve(animationId);
      if (animation == null) {
        log.finest("Failed to resolve animation with id $animationId");
      } else {
        animation.internalAddKeyedObject(this);
      }
    }
  }

  @override
  void onRemoved() => animation?.internalRemoveKeyedObject(this);

  /// Called by rive_core to add a KeyedObject to the animation. This should be
  /// @internal when it's supported.
  bool internalAddKeyedProperty(KeyedProperty property) {
    var value = _keyedProperties[property.propertyKey];

    // If the property is already keyed, that's ok just make sure the
    // KeyedObject matches.
    if (value != null) {
      assert(
          value == property,
          'Trying to add a KeyedProperty for a property'
          'that\'s already keyed in this Animation?!');
      return false;
    }
    _keyedProperties[property.propertyKey] = property;
    return true;
  }

  /// Called by rive_core to remove a KeyedObject to the animation. This should
  /// be @internal when it's supported.
  bool internalRemoveKeyedProperty(KeyedProperty property) {
    var removed = _keyedProperties.remove(property.propertyKey);
    assert(removed == null || removed == property);
    return removed != null;
  }

  /// Get the keyed data for a property already in this keyed object.
  KeyedProperty getKeyed(int propertyKey) => _keyedProperties[propertyKey];

  /// Key a property for the object represented. Expects that the property is
  /// not yet keyed. Use [getKeyed] to see if it's already keyed.
  KeyedProperty makeKeyed(int propertyKey) {
    assert(getKeyed(propertyKey) == null,
        'Property should not already be keyed in this object.');
    assert(context != null && id != null,
        'KeyedProperty should already be added to Core.');

    var keyedProperty = KeyedProperty()
      ..keyedObjectId = id
      ..propertyKey = propertyKey;
    context.add(keyedProperty);

    // N.B. we don't add the keyed property manually here as it gets added by us
    // adding it to core. This let's us reuse the same codepath for
    // keyedProperty's making it into the _keyedProperties map.

    // However, we can make sure that it is there.
    assert(getKeyed(propertyKey) == keyedProperty);

    return keyedProperty;
  }

  /// Pass in a different [core] context if you want to apply the animation to a
  /// different instance. This isn't meant to be used yet but left as mostly a
  /// note to remember that at runtime we have to support applying animtaions to
  /// instances. We do a nice job of not duping all that data at runtime (so
  /// animations exist once but entire Rive file can be instanced multiple times
  /// playing different positions).
  void apply(int time, double mix, {RiveFile coreContext}) {
    coreContext ??= context;
    core.Core object = coreContext.resolve(objectId);
    if (object == null) {
      return;
    }
    for (final keyedProperty in _keyedProperties.values) {
      keyedProperty.apply(time, mix, object);
    }
  }
}
