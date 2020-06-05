import 'dart:collection';

import 'package:rive_core/animation/keyframe.dart';
import 'package:core/id.dart';
import 'package:core/core.dart';
import 'package:rive_core/animation/keyframe_draw_order_value.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/src/generated/animation/keyframe_draw_order_base.dart';

class KeyFrameDrawOrder extends KeyFrameDrawOrderBase {
  final HashSet<KeyFrameDrawOrderValue> _values =
      HashSet<KeyFrameDrawOrderValue>();

  // Meant to be @internal when supported...
  bool internalAddValue(KeyFrameDrawOrderValue value) {
    if (_values.contains(value)) {
      return false;
    }
    _values.add(value);
    // -> editor-only
    internalValueChanged();
    // <- editor-only
    return true;
  }

  // Meant to be @internal when supported...
  bool internalRemoveValue(KeyFrameDrawOrderValue value) {
    if (_values.remove(value)) {
      // -> editor-only
      internalValueChanged();
      // <- editor-only
      return true;
    }
    return false;
  }

  @override
  void apply(Core<CoreContext> object, int propertyKey, double mix) {
    for (final value in _values) {
      value.apply(object.context);
    }
  }

  @override
  void applyInterpolation(Core<CoreContext> object, int propertyKey,
      double seconds, KeyFrame nextFrame, double mix) {
    apply(object, propertyKey, mix);
  }

  @override
  void keyedPropertyIdChanged(Id from, Id to) {
    // TODO: implement keyedPropertyIdChanged
  }

  @override
  void valueFrom(Artboard artboard, int propertyKey) {
    var core = artboard.context;
    core.batchAdd(() {
      for (final drawable in artboard.drawables) {
        // Find a value object with the drawable's id, if not, make one and set
        // the value.
        var keyFrameValue = _values.firstWhere(
            (keyFrameValue) => keyFrameValue.drawableId == drawable.id,
            orElse: () => core.addObject(KeyFrameDrawOrderValue()
              ..drawableId = drawable.id
              ..keyframeId = id));

        keyFrameValue.value = drawable.drawOrder;
      }
    });
  }
}
