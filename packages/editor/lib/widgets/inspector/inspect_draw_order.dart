import 'package:core/id.dart';
import 'package:flutter/material.dart';
import 'package:rive_core/drawable.dart';
import 'package:rive_core/transform_component.dart';
import 'package:rive_editor/widgets/inspector/inspection_set.dart';
import 'package:rive_editor/widgets/inspector/inspector_builder.dart';
import 'package:rive_editor/widgets/inspector/inspector_group.dart';
import 'package:rive_editor/widgets/inspector/properties/property_draw_target.dart';
import 'package:rive_editor/widgets/inspector/properties/property_normal_draw.dart';
import 'package:rive_core/draw_rules.dart';
import 'package:rive_core/draw_target.dart';
import 'package:rive_editor/widgets/inspector/select_stage_item_helper.dart';
import 'package:rive_editor/widgets/ui_strings.dart';

class InspectDrawOrder extends ListenableInspectorBuilder {
  final SelectStageItemHelper selectionHelper = SelectStageItemHelper();
  bool _isExpanded = true;
  TransformComponent _drawOrderComponent;

  void _createDrawTarget(InspectionSet inspecting) {
    var file = inspecting.fileContext.core;
    file.batchAdd(() {
      var rules = _drawOrderComponent.drawRules;
      if (rules == null) {
        // Make the draw rules object
        rules = DrawRules();
        file.addObject(rules);
        _drawOrderComponent.appendChild(rules);
      }
      var target = DrawTarget();
      file.addObject(target);
      rules.appendChild(target);
    });
    file.captureJournalEntry();
  }

  @override
  List<WidgetBuilder> expand(
          BuildContext panelContext, InspectionSet inspecting) =>
      [
        (context) => InspectorGroup(
              name: 'Draw Order',
              isExpanded: _isExpanded,
              tapExpand: () {
                _isExpanded = !_isExpanded;
                notifyListeners();
              },
              add: () {
                _createDrawTarget(inspecting);
              },
            ),
        if (_isExpanded && _drawOrderComponent.drawRules != null)
          (context) => PropertyNormalDraw(
                isActive: _drawOrderComponent.drawRules?.activeTarget == null,
                activate: () => _changeDrawTarget(null),
              ),
        if (_isExpanded && _drawOrderComponent.drawRules != null)
          for (final drawTarget in _drawOrderComponent.drawRules.targets)
            (context) => PropertyDrawTarget(
                  target: drawTarget,
                  isActive:
                      _drawOrderComponent.drawRules?.activeTarget == drawTarget,
                  activate: () => _changeDrawTarget(drawTarget),
                  pickTarget: () async {
                    var drawables = await selectionHelper.show(
                        inspecting.fileContext,
                        UIStrings.of(context).withKey('select_drawable_target'),
                        (item) => item.component is Drawable);
                    if (drawables.isNotEmpty) {
                      drawTarget.drawable =
                          drawables.first.component as Drawable;
                    }
                  },
                )
      ];

  void _changeDrawTarget(DrawTarget target) {
    _drawOrderComponent.drawRules?.drawTargetId = target?.id ?? emptyId;
    _drawOrderComponent.context?.captureJournalEntry();
  }

  @override
  bool validate(InspectionSet inspecting) {
    if (inspecting.components.length != 1) {
      return false;
    }
    var selectedComponent = inspecting.components.first;
    if (selectedComponent is TransformComponent) {
      _drawOrderComponent = selectedComponent;
      changeWhen([selectedComponent.drawRulesChanged]);
      return true;
    }
    return false;
  }
}
