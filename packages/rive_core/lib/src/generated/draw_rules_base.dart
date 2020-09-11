/// Core automatically generated lib/src/generated/draw_rules_base.dart.
/// Do not modify manually.

import 'dart:collection';
import 'package:core/core.dart';
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
  /// DrawTargetId field with key 120.
  Id _drawTargetId;
  static const int drawTargetIdPropertyKey = 120;

  /// Id of the DrawTarget that is currently active for this set of rules.
  Id get drawTargetId => _drawTargetId;

  /// Change the [_drawTargetId] field value.
  /// [drawTargetIdChanged] will be invoked only if the field's value has
  /// changed.
  set drawTargetId(Id value) {
    if (_drawTargetId == value) {
      return;
    }
    Id from = _drawTargetId;
    _drawTargetId = value;
    onPropertyChanged(drawTargetIdPropertyKey, from, value);
    drawTargetIdChanged(from, value);
  }

  void drawTargetIdChanged(Id from, Id to);

  @override
  void changeNonNull() {
    super.changeNonNull();
    if (drawTargetId != null) {
      onPropertyChanged(drawTargetIdPropertyKey, drawTargetId, drawTargetId);
    }
  }

  @override
  void writeRuntimeProperties(BinaryWriter writer, HashMap<Id, int> idLookup) {
    super.writeRuntimeProperties(writer, idLookup);
    if (_drawTargetId != null && exports(drawTargetIdPropertyKey)) {
      var value = idLookup[_drawTargetId];
      if (value != null) {
        context.uintType
            .writeRuntimeProperty(drawTargetIdPropertyKey, writer, value);
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
