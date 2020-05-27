/// Core automatically generated
/// lib/src/generated/animation/keyed_property_base.dart.
/// Do not modify manually.

import 'dart:collection';
import 'package:core/core.dart';
import 'package:rive_core/src/generated/rive_core_context.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

abstract class KeyedPropertyBase<T extends RiveCoreContext> extends Core<T> {
  static const int typeKey = 26;
  @override
  int get coreType => KeyedPropertyBase.typeKey;
  @override
  Set<int> get coreTypes => {KeyedPropertyBase.typeKey};

  /// --------------------------------------------------------------------------
  /// KeyedObjectId field with key 71.
  Id _keyedObjectId;
  static const int keyedObjectIdPropertyKey = 71;

  /// The id of the KeyedObject this KeyedProperty belongs to.
  Id get keyedObjectId => _keyedObjectId;

  /// Change the [_keyedObjectId] field value.
  /// [keyedObjectIdChanged] will be invoked only if the field's value has
  /// changed.
  set keyedObjectId(Id value) {
    if (_keyedObjectId == value) {
      return;
    }
    Id from = _keyedObjectId;
    _keyedObjectId = value;
    onPropertyChanged(keyedObjectIdPropertyKey, from, value);
    keyedObjectIdChanged(from, value);
  }

  void keyedObjectIdChanged(Id from, Id to);

  /// --------------------------------------------------------------------------
  /// PropertyKey field with key 53.
  int _propertyKey;
  static const int propertyKeyPropertyKey = 53;

  /// The property type that is keyed.
  int get propertyKey => _propertyKey;

  /// Change the [_propertyKey] field value.
  /// [propertyKeyChanged] will be invoked only if the field's value has
  /// changed.
  set propertyKey(int value) {
    if (_propertyKey == value) {
      return;
    }
    int from = _propertyKey;
    _propertyKey = value;
    onPropertyChanged(propertyKeyPropertyKey, from, value);
    propertyKeyChanged(from, value);
  }

  void propertyKeyChanged(int from, int to);

  @override
  void changeNonNull() {
    if (keyedObjectId != null) {
      onPropertyChanged(keyedObjectIdPropertyKey, keyedObjectId, keyedObjectId);
    }
    if (propertyKey != null) {
      onPropertyChanged(propertyKeyPropertyKey, propertyKey, propertyKey);
    }
  }

  @override
  void writeRuntimeProperties(BinaryWriter writer, HashMap<Id, int> idLookup) {
    if (_propertyKey != null) {
      context.intType
          .writeProperty(propertyKeyPropertyKey, writer, _propertyKey);
    }
  }

  @override
  K getProperty<K>(int propertyKey) {
    switch (propertyKey) {
      case keyedObjectIdPropertyKey:
        return keyedObjectId as K;
      case propertyKeyPropertyKey:
        return propertyKey as K;
      default:
        return super.getProperty<K>(propertyKey);
    }
  }

  @override
  bool hasProperty(int propertyKey) {
    switch (propertyKey) {
      case keyedObjectIdPropertyKey:
      case propertyKeyPropertyKey:
        return true;
      default:
        return super.hasProperty(propertyKey);
    }
  }
}
