/// Core automatically generated
/// lib/src/generated/animation/keyed_object_base.dart.
/// Do not modify manually.

import 'package:core/core.dart';
import 'package:rive_core/src/generated/rive_core_context.dart';

abstract class KeyedObjectBase<T extends RiveCoreContext> extends Core<T> {
  static const int typeKey = 25;
  @override
  int get coreType => KeyedObjectBase.typeKey;
  @override
  Set<int> get coreTypes => {KeyedObjectBase.typeKey};

  /// --------------------------------------------------------------------------
  /// ObjectId field with key 51.
  Id _objectId;
  static const int objectIdPropertyKey = 51;

  /// Identifier used to track the object that is keyed.
  Id get objectId => _objectId;

  /// Change the [_objectId] field value.
  /// [objectIdChanged] will be invoked only if the field's value has changed.
  set objectId(Id value) {
    if (_objectId == value) {
      return;
    }
    Id from = _objectId;
    _objectId = value;
    onPropertyChanged(objectIdPropertyKey, from, value);
    objectIdChanged(from, value);
  }

  void objectIdChanged(Id from, Id to);

  /// --------------------------------------------------------------------------
  /// AnimationId field with key 52.
  Id _animationId;
  static const int animationIdPropertyKey = 52;

  /// The id of the animation this keyed object is in.
  Id get animationId => _animationId;

  /// Change the [_animationId] field value.
  /// [animationIdChanged] will be invoked only if the field's value has
  /// changed.
  set animationId(Id value) {
    if (_animationId == value) {
      return;
    }
    Id from = _animationId;
    _animationId = value;
    onPropertyChanged(animationIdPropertyKey, from, value);
    animationIdChanged(from, value);
  }

  void animationIdChanged(Id from, Id to);

  @override
  void changeNonNull() {
    if (objectId != null) {
      onPropertyChanged(objectIdPropertyKey, objectId, objectId);
    }
    if (animationId != null) {
      onPropertyChanged(animationIdPropertyKey, animationId, animationId);
    }
  }

  @override
  K getProperty<K>(int propertyKey) {
    switch (propertyKey) {
      case objectIdPropertyKey:
        return objectId as K;
      case animationIdPropertyKey:
        return animationId as K;
      default:
        return super.getProperty<K>(propertyKey);
    }
  }

  @override
  bool hasProperty(int propertyKey) {
    switch (propertyKey) {
      case objectIdPropertyKey:
      case animationIdPropertyKey:
        return true;
      default:
        return super.hasProperty(propertyKey);
    }
  }
}
