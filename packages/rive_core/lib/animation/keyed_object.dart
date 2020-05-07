import 'dart:collection';

import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:rive_core/animation/keyed_property.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/event.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/src/generated/animation/keyed_object_base.dart';

import 'linear_animation.dart';
export 'package:rive_core/src/generated/animation/keyed_object_base.dart';

final _log = Logger('animation');

class KeyedObject extends KeyedObjectBase<RiveFile> {
  final HashMap<int, KeyedProperty> _keyedProperties =
      HashMap<int, KeyedProperty>();

  int _lastFrame = 0;

  /// The last frame with a keyframe on it.
  int get lastFrame => _lastFrame;

  Iterable<KeyedProperty> get keyedProperties => _keyedProperties.values;

  final Event _keyframesMoved = Event();
  // Dispatches whenever one or many keyframes have their time changed.
  Listenable get keyframesMoved => _keyframesMoved;

  @override
  void onAdded() {
    if (animationId != null) {
      LinearAnimation animation = context?.resolve(animationId);
      if (animation == null) {
        _log.finest("Failed to resolve animation with id $animationId");
      } else {
        animation.internalAddKeyedObject(this);
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
      component.whenDeleted(_removeAll);
    }
  }

  void _removeAll() {
    assert(context != null);
    // Copy lists to not modify them while iterating.
    var kps = _keyedProperties.values.toList(growable: false);
    for (final keyedProperty in kps) {
      var keyframes = keyedProperty.keyframes.toList(growable: false);
      keyframes.forEach(context.remove);
      context.remove(keyedProperty);
    }
    context.remove(this);
  }

  LinearAnimation get animation => context?.resolve(animationId);

  @override
  void onAddedDirty() {}

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
    if (removed != null) {
      /// Keyed property removed, it may have contained keyframes.
      internalKeyFramesChanged();
    }
    if (_keyedProperties.isEmpty) {
      // Remove this keyed property.
      context.remove(this);
    }
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

  void apply(double time, double mix, RiveCoreContext coreContext) {
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

  // Should be @internal when supported...
  void internalKeyFramesChanged() {
    _computeLastKeyFrameTime();
    animation?.internalKeyFramesChanged();
  }

  // Should be @internal when supported...
  void internalKeyFramesMoved() => _keyframesMoved.notify();

  /// Should be @internal when supported.
  void internalKeyFrameValueChanged() =>
      animation?.internalKeyFrameValueChanged();

  void _computeLastKeyFrameTime() {
    _lastFrame = 0;
    for (final property in _keyedProperties.values) {
      if (property.lastFrame > _lastFrame) {
        _lastFrame = property.lastFrame;
      }
    }
  }
}
