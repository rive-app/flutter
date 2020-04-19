import 'dart:collection';

import 'package:core/core.dart';
import 'package:logging/logging.dart';
import 'package:rive_core/animation/keyed_property.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/src/generated/animation/keyed_object_base.dart';

import 'linear_animation.dart';
export 'package:rive_core/src/generated/animation/keyed_object_base.dart';

final _log = Logger('animation');

class KeyedObject extends KeyedObjectBase<RiveFile> {
  final HashMap<int, KeyedProperty> _keyedProperties =
      HashMap<int, KeyedProperty>();

  @override
  void onAdded() {}

  LinearAnimation get animation => context?.resolve(animationId);

  @override
  void onAddedDirty() {
    if (animationId != null) {
      LinearAnimation animation = context?.resolve(animationId);
      if (animation == null) {
        _log.finest("Failed to resolve animation with id $animationId");
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
          'that\'s already keyed in this LinearAnimation?!');
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

    // We also add it here in case we're doing a batch add (onAddedDirty will be
    // called later for the keyedObject).
    internalAddKeyedProperty(keyedProperty);

    // However, we can make sure that it is there.
    assert(getKeyed(propertyKey) == keyedProperty);

    return keyedProperty;
  }

  void apply(double time, double mix, RiveFile coreContext) {
    Core object = coreContext.resolve(objectId);
    if (object == null) {
      return;
    }
    for (final keyedProperty in _keyedProperties.values) {
      keyedProperty.apply(time, mix, object);
    }
  }

  @override
  void animationIdChanged(Id from, Id to) {}

  @override
  void objectIdChanged(Id from, Id to) {}
}
