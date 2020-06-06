import 'dart:collection';

import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:rive_core/animation/keyed_property.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/event.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/src/generated/animation/keyed_object_base.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';
import 'linear_animation.dart';
export 'package:rive_core/src/generated/animation/keyed_object_base.dart';

final _log = Logger('animation');

class KeyedObject extends KeyedObjectBase<RiveFile> {
  final HashMap<int, KeyedProperty> _keyedProperties =
      HashMap<int, KeyedProperty>();

  Iterable<KeyedProperty> get keyedProperties => _keyedProperties.values;

  final Event _keyframesMoved = Event();
  //component.whenDeleted(_removeAll); Dispatches whenever one or many keyframes have their time changed.
  Listenable get keyframesMoved => _keyframesMoved;

  @override
  void onAdded() {
    // -> editor-only
    if (animationId != null) {
      LinearAnimation animation = context?.resolve(animationId);
      if (animation == null) {
        _log.severe("Failed to resolve animation with id $animationId");
        context?.removeObject(this);
      } else if (objectId == null) {
        _log.severe("Found a keyed object referenced null objectId");
        context?.removeObject(this);
      } else {
        animation.internalAddKeyedObject(this);
      }
    }
    // <- editor-only

    // TODO: shouldn't this be editor only?
    // Validate the object we're keying actually exists. By the time "onAdded"
    // is called, the file should be in a stable state.
    Component component;
    if (objectId == null ||
        (component = context?.resolve<Component>(objectId)) == null) {
      _log.finest('Removing KeyedObject as we couldn\'t '
          'resolve an object with id $objectId.');
      _removeAll();
    } else {
      component.whenDeleted(_removeAll);
    }
  }

  void _removeAll() {
    assert(context != null);
    // Copy lists to not modify them while iterating.
    var kps = _keyedProperties.values.toList(growable: false);
    for (final keyedProperty in kps) {
      var keyframes = keyedProperty.keyframes.toList(growable: false);
      keyframes.forEach(context.removeObject);
      context.removeObject(keyedProperty);
    }
    context.removeObject(this);
  }

  // -> editor-only
  LinearAnimation get animation => context?.resolve(animationId);
  // <- editor-only

  @override
  void onAddedDirty() {}

  @override
  void onRemoved() {
    // -> editor-only
    animation?.internalRemoveKeyedObject(this);
    // <- editor-only
  }

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
    // -> editor-only
    if (removed != null) {
      /// Keyed property removed, it may have contained keyframes.
      internalKeyFramesChanged();
    }
    // <- editor-only
    if (_keyedProperties.isEmpty) {
      // Remove this keyed property.
      context.removeObject(this);
    }
    assert(removed == null || removed == property);
    return removed != null;
  }

  // -> editor-only
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
    context.addObject(keyedProperty);

    // We also add it here in case we're doing a batch add (onAddedDirty will be
    // called later for the keyedObject).
    internalAddKeyedProperty(keyedProperty);

    // However, we can make sure that it is there.
    assert(getKeyed(propertyKey) == keyedProperty);

    return keyedProperty;
  }
  // <- editor-only

  void apply(double time, double mix, CoreContext coreContext) {
    Core object = coreContext.resolve(objectId);
    if (object == null) {
      return;
    }
    for (final keyedProperty in _keyedProperties.values) {
      keyedProperty.apply(time, mix, object);
    }
  }

  // -> editor-only
  @override
  void animationIdChanged(Id from, Id to) {}
  // <- editor-only

  @override
  void objectIdChanged(Id from, Id to) {}

  // -> editor-only
  // Should be @internal when supported...
  void internalKeyFramesChanged() {
    animation?.internalKeyFramesChanged();
  }

  // Should be @internal when supported...
  void internalKeyFramesMoved() => _keyframesMoved.notify();

  /// Should be @internal when supported.
  void internalKeyFrameValueChanged() =>
      animation?.internalKeyFrameValueChanged();

  @override
  void writeRuntime(BinaryWriter writer, [HashMap<Id, int> idLookup]) {
    super.writeRuntime(writer, idLookup);
    writer.writeVarUint(_keyedProperties.length);
    for (final keyedProperty in _keyedProperties.values) {
      keyedProperty.writeRuntime(writer, idLookup);
    }
  }
  // <- editor-only
}
