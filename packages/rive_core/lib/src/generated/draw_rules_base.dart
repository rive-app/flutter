/// Core automatically generated lib/src/generated/draw_rules_base.dart.
/// Do not modify manually.

import 'dart:collection';
import 'package:core/core.dart';
import 'package:core/field_types/core_field_type.dart';
import 'package:core/key_state.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/src/generated/component_base.dart';
import 'package:rive_core/src/generated/container_component_base.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

abstract class DrawRulesBase extends ContainerComponent {
  static const int typeKey = 49;
  @override
  int get coreType => DrawRulesBase.typeKey;
  @override
  Set<int> get coreTypes => {
        DrawRulesBase.typeKey,
        ContainerComponentBase.typeKey,
        ComponentBase.typeKey
      };

  /// --------------------------------------------------------------------------
  /// DrawTargetId field with key 121.
  Id _drawTargetId;
  Id _drawTargetIdAnimated;
  KeyState _drawTargetIdKeyState = KeyState.none;
  static const int drawTargetIdPropertyKey = 121;

  /// Id of the DrawTarget that is currently active for this set of rules.
  /// Get the [_drawTargetId] field value.Note this may not match the core value
  /// if animation mode is active.
  Id get drawTargetId => _drawTargetIdAnimated ?? _drawTargetId;

  /// Get the non-animation [_drawTargetId] field value.
  Id get drawTargetIdCore => _drawTargetId;

  /// Change the [_drawTargetId] field value.
  /// [drawTargetIdChanged] will be invoked only if the field's value has
  /// changed.
  set drawTargetIdCore(Id value) {
    if (_drawTargetId == value) {
      return;
    }
    Id from = _drawTargetId;
    _drawTargetId = value;
    onPropertyChanged(drawTargetIdPropertyKey, from, value);
    drawTargetIdChanged(from, value);
  }

  set drawTargetId(Id value) {
    if (drawTargetId == value) {
      return;
    }
    if (context != null && context.isAnimating) {
      _drawTargetIdAnimate(value, true);
      return;
    }
    drawTargetIdCore = value;
  }

  void _drawTargetIdAnimate(Id value, bool autoKey) {
    if (_drawTargetIdAnimated == value) {
      return;
    }
    Id from = drawTargetId;
    _drawTargetIdAnimated = value;
    Id to = drawTargetId;
    onAnimatedPropertyChanged(drawTargetIdPropertyKey, autoKey, from, to);
    drawTargetIdChanged(from, to);
  }

  Id get drawTargetIdAnimated => _drawTargetIdAnimated;
  set drawTargetIdAnimated(Id value) => _drawTargetIdAnimate(value, false);
  KeyState get drawTargetIdKeyState => _drawTargetIdKeyState;
  set drawTargetIdKeyState(KeyState value) {
    if (_drawTargetIdKeyState == value) {
      return;
    }
    _drawTargetIdKeyState = value;
    // Force update anything listening on this property.
    onAnimatedPropertyChanged(drawTargetIdPropertyKey, false,
        _drawTargetIdAnimated, _drawTargetIdAnimated);
  }

  void drawTargetIdChanged(Id from, Id to);

  @override
  void changeNonNull() {
    super.changeNonNull();
    if (_drawTargetId != null) {
      onPropertyChanged(drawTargetIdPropertyKey, _drawTargetId, _drawTargetId);
    }
  }

  @override
  void writeRuntimeProperties(BinaryWriter writer,
      HashMap<int, CoreFieldType> propertyToField, HashMap<Id, int> idLookup) {
    super.writeRuntimeProperties(writer, propertyToField, idLookup);
    if (_drawTargetId != null && exports(drawTargetIdPropertyKey)) {
      var value = idLookup[_drawTargetId];
      if (value != null) {
        context.uintType.writeRuntimeProperty(
            drawTargetIdPropertyKey, writer, value, propertyToField);
      }
    }
  }

  @override
  K getProperty<K>(int propertyKey) {
    switch (propertyKey) {
      case drawTargetIdPropertyKey:
        return drawTargetId as K;
      default:
        return super.getProperty<K>(propertyKey);
    }
  }

  @override
  bool hasProperty(int propertyKey) {
    switch (propertyKey) {
      case drawTargetIdPropertyKey:
        return true;
      default:
        return super.hasProperty(propertyKey);
    }
  }
}
