import 'dart:collection';

import 'package:core/core.dart';
import 'package:core/field_types/core_field_type.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:rive_core/animation/keyed_property.dart';
import 'package:rive_core/animation/keyframe.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/event.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/src/generated/animation/keyed_object_base.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';
import 'linear_animation.dart';
export 'package:rive_core/src/generated/animation/keyed_object_base.dart';

// -> editor-only
final _log = Logger('animation');
// <- editor-only

class KeyedObject extends KeyedObjectBase<RiveFile> {
  final HashMap<int, KeyedProperty> _keyedProperties =
      HashMap<int, KeyedProperty>();

  Iterable<KeyedProperty> get keyedProperties => _keyedProperties.values;

  // -> editor-only
  final Event _keyframesMoved = Event();
  Listenable get keyframesMoved => _keyframesMoved;
  // <- editor-only

  @override
  void onAdded() {
    // -> editor-only
    if (animationId != null) {
      LinearAnimation animation = context?.resolve(animationId);
      if (animation == null) {
        _log.severe('Failed to resolve animation with id $animationId');
        context?.removeObject(this);
      } else if (objectId == null) {
        _log.severe('Found a keyed object referenced null objectId');
        context?.removeObject(this);
      } else if (!animation.internalAddKeyedObject(this)) {
        // Somehow had a duplicate keyed object in the animation referenced.
        context?.removeObject(this);
      }
    }

    // Validate the object we're keying actually exists. By the time "onAdded"
    // is called, the file should be in a stable state.
    Component component;
    if (objectId == null ||
        (component = context?.resolve<Component>(objectId)) == null) {
      _log.finest('Removing KeyedObject as we couldn\'t '
          'resolve an object with id $objectId.');
      _removeAll();
    } else {
      component.whenRemoved(_removeAll);
    }
    // <- editor-only
  }

  // -> editor-only
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

  /// Called by rive_core to add a KeyedProperty to the animation. This should
  /// be @internal when it's supported.
  bool internalAddKeyedProperty(KeyedProperty property) {
    var value = _keyedProperties[property.propertyKey];

    // If the property is already keyed, that's ok just make sure the
    // KeyedObject matches.
    if (value != null && value != property) {
      // -> editor-only
      _log.severe('Trying to add a KeyedProperty for a property'
          'that\'s already keyed in this LinearAnimation?!');
      // <- editor-only
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
    // assert(removed == null || removed == property,
    //     '$removed was not $property or null');
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
  void writeRuntime(
      BinaryWriter writer, HashMap<int, CoreFieldType> propertyToField,
      [HashMap<Id, int> idLookup]) {
    super.writeRuntime(writer, propertyToField, idLookup);
    // Export only properties that actually contain keyframes.
    var exportProperties =
        keyedProperties.where((property) => property.keyframes.isNotEmpty);
    writer.writeVarUint(exportProperties.length);
    for (final keyedProperty in exportProperties) {
      keyedProperty.writeRuntime(writer, propertyToField, idLookup);
    }
  }

  // Write only a specific set of keyed properties and keyframes for this keyed
  // object (helpful when copy pasting).
  void writeRuntimeSubset(
      BinaryWriter writer,
      HashMap<KeyedProperty, HashSet<KeyFrame>> subset,
      HashMap<int, CoreFieldType> propertyToField,
      [HashMap<Id, int> idLookup]) {
    super.writeRuntime(writer, propertyToField, idLookup);
    writer.writeVarUint(subset.keys.length);
    for (final keyedProperty in subset.keys) {
      keyedProperty.writeRuntimeSubset(
          writer, propertyToField, subset[keyedProperty], idLookup);
    }
  }
  // <- editor-only
}
