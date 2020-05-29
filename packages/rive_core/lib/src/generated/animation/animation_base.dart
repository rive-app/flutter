/// Core automatically generated
/// lib/src/generated/animation/animation_base.dart.
/// Do not modify manually.

import 'dart:collection';
import 'package:core/core.dart';
import 'package:rive_core/src/generated/rive_core_context.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

abstract class AnimationBase<T extends RiveCoreContext> extends Core<T> {
  static const int typeKey = 27;
  @override
  int get coreType => AnimationBase.typeKey;
  @override
  Set<int> get coreTypes => {AnimationBase.typeKey};

  /// --------------------------------------------------------------------------
  /// ArtboardId field with key 54.
  Id _artboardId;
  static const int artboardIdPropertyKey = 54;

  /// Identifier used to track the artboard this animation belongs to.
  Id get artboardId => _artboardId;

  /// Change the [_artboardId] field value.
  /// [artboardIdChanged] will be invoked only if the field's value has changed.
  set artboardId(Id value) {
    if (_artboardId == value) {
      return;
    }
    Id from = _artboardId;
    _artboardId = value;
    onPropertyChanged(artboardIdPropertyKey, from, value);
    artboardIdChanged(from, value);
  }

  void artboardIdChanged(Id from, Id to);

  /// --------------------------------------------------------------------------
  /// Name field with key 55.
  String _name;
  static const int namePropertyKey = 55;

  /// Name of the animation.
  String get name => _name;

  /// Change the [_name] field value.
  /// [nameChanged] will be invoked only if the field's value has changed.
  set name(String value) {
    if (_name == value) {
      return;
    }
    String from = _name;
    _name = value;
    onPropertyChanged(namePropertyKey, from, value);
    nameChanged(from, value);
  }

  void nameChanged(String from, String to);

  /// --------------------------------------------------------------------------
  /// Order field with key 73.
  FractionalIndex _order;
  static const int orderPropertyKey = 73;

  /// Order this animation shows up in the animations list.
  FractionalIndex get order => _order;

  /// Change the [_order] field value.
  /// [orderChanged] will be invoked only if the field's value has changed.
  set order(FractionalIndex value) {
    if (_order == value) {
      return;
    }
    FractionalIndex from = _order;
    _order = value;
    onPropertyChanged(orderPropertyKey, from, value);
    orderChanged(from, value);
  }

  void orderChanged(FractionalIndex from, FractionalIndex to);

  @override
  void changeNonNull() {
    if (artboardId != null) {
      onPropertyChanged(artboardIdPropertyKey, artboardId, artboardId);
    }
    if (name != null) {
      onPropertyChanged(namePropertyKey, name, name);
    }
    if (order != null) {
      onPropertyChanged(orderPropertyKey, order, order);
    }
  }

  @override
  void writeRuntimeProperties(BinaryWriter writer, HashMap<Id, int> idLookup) {
    if (_name != null) {
      context.stringType.writeProperty(namePropertyKey, writer, _name);
    }
  }

  @override
  K getProperty<K>(int propertyKey) {
    switch (propertyKey) {
      case artboardIdPropertyKey:
        return artboardId as K;
      case namePropertyKey:
        return name as K;
      case orderPropertyKey:
        return order as K;
      default:
        return super.getProperty<K>(propertyKey);
    }
  }

  @override
  bool hasProperty(int propertyKey) {
    switch (propertyKey) {
      case artboardIdPropertyKey:
      case namePropertyKey:
      case orderPropertyKey:
        return true;
      default:
        return super.hasProperty(propertyKey);
    }
  }
}
