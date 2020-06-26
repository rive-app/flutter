import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rive_core/drawable.dart';
import 'package:rive_core/node.dart';
import 'package:rive_editor/widgets/common/combo_box.dart';
import 'package:rive_editor/widgets/common/core_combo_box.dart';
import 'package:rive_editor/widgets/common/inspector_row.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/inspector/inspection_set.dart';
import 'package:rive_editor/widgets/inspector/inspector_builder.dart';
import 'package:rive_editor/widgets/inspector/properties/property_dual.dart';
import 'package:rive_editor/widgets/ui_strings.dart';

List<BlendMode> displayBlendModes = [
  BlendMode.srcOver,
  null,
  BlendMode.darken,
  BlendMode.multiply,
  BlendMode.colorBurn,
  null,
  BlendMode.lighten,
  BlendMode.screen,
  BlendMode.colorDodge,
  null,
  BlendMode.overlay,
  BlendMode.softLight,
  BlendMode.hardLight,
  null,
  BlendMode.difference,
  BlendMode.exclusion,
  null,
  BlendMode.hue,
  BlendMode.saturation,
  BlendMode.color,
  BlendMode.luminosity,
];

/// Returns the inspector for Artboard selections.
class BlendInspectorBuilder extends ListenableInspectorBuilder {
  @override
  bool validate(InspectionSet inspecting) =>
      inspecting.intersectingCoreTypes.contains(NodeBase.typeKey);

  @override
  List<WidgetBuilder> expand(InspectionSet inspecting) {
    return [
      (context) {
        var disableBlendMode =
            !inspecting.intersectingCoreTypes.contains(DrawableBase.typeKey);
        return Padding(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 7,
            bottom: 10,
          ),
          child: InspectorRow(
            label: Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                'Blend',
                style: RiveTheme.of(context).textStyles.inspectorPropertyLabel,
              ),
            ),
            expandColumnA: true,
            columnA: CoreComboBox(
              disabled: disableBlendMode,
              sizing: ComboSizing.sized,
              typeahead: true,
              objects: inspecting.components,
              propertyKey: DrawableBase.blendModeValuePropertyKey,
              options: displayBlendModes,
              change: (BlendMode value) {},
              toLabel: (BlendMode value) => value == null
                  ? null
                  : UIStrings.find(context).withKey(describeEnum(value)),
              toCoreValue: (BlendMode value) => value.index,
              fromCoreValue: (int value) => BlendMode.values[value],
            ),
          ),
        );
      },
      (context) => PropertyDual<double>(
            name: '',
            objects: inspecting.components,
            propertyKeyA: NodeBase.opacityPropertyKey,
            labelA: 'Opacity',
            propertyKeyB: null,
          )
    ];
  }
}
