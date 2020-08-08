import 'dart:collection';

import 'package:rive_core/animation/keyframe.dart';
import 'package:core/id.dart';
import 'package:core/core.dart';
import 'package:rive_core/animation/keyframe_draw_order_value.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/src/generated/animation/keyframe_draw_order_base.dart';
import 'package:rive_core/src/generated/animation/keyframe_draw_order_value_base.dart';
import 'package:utilities/binary_buffer/binary_reader.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

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

  // -> editor-only
  @override
  void keyedPropertyIdChanged(Id from, Id to) {
    // TODO: implement keyedPropertyIdChanged
  }
  // <- editor-only

  // -> editor-only
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

  @override
  void writeRuntime(BinaryWriter writer, [HashMap<Id, int> idLookup]) {
    super.writeRuntime(writer, idLookup);
    writer.writeVarUint(_values.length);

    var list = _ExportOrderHelper();
    list.addAll(_values);
    list.sortFractional();

    for (int i = 0; i < list.length; i++) {
      final value = list[i];
      int integerId = idLookup[value.drawableId];
      assert(integerId != null);
      assert(integerId >= 0);
      writer.writeVarUint(integerId);
    }
  }

  void readRuntimeValues(
      CoreContext core, BinaryReader reader, RuntimeRemap<int, Id> idRemap) {
    int numValues = reader.readVarUint();

    var values = List<KeyFrameDrawOrderValue>(numValues);
    for (int i = 0; i < numValues; i++) {
      var valueObject =
          core.addObject(KeyFrameDrawOrderValue()..keyframeId = id);

      idRemap.add(valueObject, KeyFrameDrawOrderValueBase.drawableIdPropertyKey,
          reader);

      values[i] = valueObject;
    }
    var helper = _ImportOrderHelper(values);
    helper.validateFractional();
  }
  // <- editor-only
}

// -> editor-only
class _ExportOrderHelper
    extends FractionallyIndexedList<KeyFrameDrawOrderValue> {
  @override
  FractionalIndex orderOf(KeyFrameDrawOrderValue value) => value.value;

  @override
  void setOrderOf(KeyFrameDrawOrderValue value, FractionalIndex order) {
    assert(
        false,
        'should never get called we only use this '
        'to facilitate building up the integer order');
  }
}

class _ImportOrderHelper
    extends FractionallyIndexedList<KeyFrameDrawOrderValue> {
  _ImportOrderHelper(List<KeyFrameDrawOrderValue> values)
      : super(values: values);
  @override
  FractionalIndex orderOf(KeyFrameDrawOrderValue value) => value.value;

  @override
  void setOrderOf(KeyFrameDrawOrderValue value, FractionalIndex order) {
    value.value = order;
  }
}
// <- editor-only
