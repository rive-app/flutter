/// Core automatically generated
/// lib/src/generated/animation/keyframe_draw_order_value_base.dart.
/// Do not modify manually.

import 'dart:collection';
import 'package:core/core.dart';
import 'package:rive_core/src/generated/rive_core_context.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

abstract class KeyFrameDrawOrderValueBase<T extends RiveCoreContext>
    extends Core<T> {
  static const int typeKey = 33;
  @override
  int get coreType => KeyFrameDrawOrderValueBase.typeKey;
  @override
  Set<int> get coreTypes => {KeyFrameDrawOrderValueBase.typeKey};

  /// --------------------------------------------------------------------------
  /// KeyframeId field with key 76.
  Id _keyframeId;
  static const int keyframeIdPropertyKey = 76;

  /// The id of the KeyFrameDrawOrder this KeyFrameDrawOrderValue belongs to.
  Id get keyframeId => _keyframeId;

  /// Change the [_keyframeId] field value.
  /// [keyframeIdChanged] will be invoked only if the field's value has changed.
  set keyframeId(Id value) {
    if (_keyframeId == value) {
      return;
    }
    Id from = _keyframeId;
    _keyframeId = value;
    onPropertyChanged(keyframeIdPropertyKey, from, value);
    keyframeIdChanged(from, value);
  }

  void keyframeIdChanged(Id from, Id to);

  /// --------------------------------------------------------------------------
  /// DrawableId field with key 77.
  Id _drawableId;
  static const int drawableIdPropertyKey = 77;

  /// The id of the Drawable this KeyFrameDrawOrderValue's value is for.
  Id get drawableId => _drawableId;

  /// Change the [_drawableId] field value.
  /// [drawableIdChanged] will be invoked only if the field's value has changed.
  set drawableId(Id value) {
    if (_drawableId == value) {
      return;
    }
    Id from = _drawableId;
    _drawableId = value;
    onPropertyChanged(drawableIdPropertyKey, from, value);
    drawableIdChanged(from, value);
  }

  void drawableIdChanged(Id from, Id to);

  /// --------------------------------------------------------------------------
  /// Value field with key 78.
  FractionalIndex _value;
  static const int valuePropertyKey = 78;

  /// The draw order value to apply to the Drawable.
  FractionalIndex get value => _value;

  /// Change the [_value] field value.
  /// [valueChanged] will be invoked only if the field's value has changed.
  set value(FractionalIndex value) {
    if (_value == value) {
      return;
    }
    FractionalIndex from = _value;
    _value = value;
    onPropertyChanged(valuePropertyKey, from, value);
    valueChanged(from, value);
  }

  void valueChanged(FractionalIndex from, FractionalIndex to);

  @override
  void changeNonNull() {
    if (keyframeId != null) {
      onPropertyChanged(keyframeIdPropertyKey, keyframeId, keyframeId);
    }
    if (drawableId != null) {
      onPropertyChanged(drawableIdPropertyKey, drawableId, drawableId);
    }
    if (value != null) {
      onPropertyChanged(valuePropertyKey, value, value);
    }
  }

  @override
  void writeRuntimeProperties(BinaryWriter writer, HashMap<Id, int> idLookup) {
    if (_drawableId != null) {
      var value = idLookup[_drawableId];
      if (value != null) {
        context.intType.writeProperty(drawableIdPropertyKey, writer, value);
      }
    }
    if (_value != null) {
      context.fractionalIndexType
          .writeProperty(valuePropertyKey, writer, _value);
    }
  }

  @override
  K getProperty<K>(int propertyKey) {
    switch (propertyKey) {
      case keyframeIdPropertyKey:
        return keyframeId as K;
      case drawableIdPropertyKey:
        return drawableId as K;
      case valuePropertyKey:
        return value as K;
      default:
        return super.getProperty<K>(propertyKey);
    }
  }

  @override
  bool hasProperty(int propertyKey) {
    switch (propertyKey) {
      case keyframeIdPropertyKey:
      case drawableIdPropertyKey:
      case valuePropertyKey:
        return true;
      default:
        return super.hasProperty(propertyKey);
    }
  }
}
