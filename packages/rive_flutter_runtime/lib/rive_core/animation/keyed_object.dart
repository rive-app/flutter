import 'dart:collection';
import 'package:rive/src/core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:rive/rive_core/animation/keyed_property.dart';
import 'package:rive/rive_core/component.dart';
import 'package:rive/rive_core/event.dart';
import 'package:rive/src/generated/animation/keyed_object_base.dart';
import 'linear_animation.dart';

final _log = Logger('animation');

class KeyedObject extends KeyedObjectBase<RuntimeArtboard> {
  final HashMap<int, KeyedProperty> _keyedProperties =
      HashMap<int, KeyedProperty>();
  Iterable<KeyedProperty> get keyedProperties => _keyedProperties.values;
  final Event _keyframesMoved = Event();
  Listenable get keyframesMoved => _keyframesMoved;
  @override
  void onAdded() {
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
    var kps = _keyedProperties.values.toList(growable: false);
    for (final keyedProperty in kps) {
      var keyframes = keyedProperty.keyframes.toList(growable: false);
      keyframes.forEach(context.removeObject);
      context.removeObject(keyedProperty);
    }
    context.removeObject(this);
  }

  @override
  void onAddedDirty() {}
  @override
  void onRemoved() {}
  bool internalAddKeyedProperty(KeyedProperty property) {
    var value = _keyedProperties[property.propertyKey];
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

  bool internalRemoveKeyedProperty(KeyedProperty property) {
    var removed = _keyedProperties.remove(property.propertyKey);
    if (_keyedProperties.isEmpty) {
      context.removeObject(this);
    }
    assert(removed == null || removed == property);
    return removed != null;
  }

  void apply(double time, double mix, CoreContext coreContext) {
    Core object = coreContext.resolve(objectId);
    if (object == null) {
      return;
    }
    for (final keyedProperty in _keyedProperties.values) {
      keyedProperty.apply(time, mix, object);
    }
  }

  @override
  void objectIdChanged(int from, int to) {}
}
