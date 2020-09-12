import 'package:flutter/material.dart';
import 'package:rive_core/component.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/widgets/common/combo_box.dart';
import 'package:rive_editor/widgets/common/converters/string_value_converter.dart';
import 'package:rive_editor/widgets/common/core_combo_box.dart';
import 'package:rive_editor/widgets/common/core_text_field.dart';
import 'package:rive_editor/widgets/common/tinted_icon_button.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/inspector/inspector_pill_button.dart';
import 'package:rive_editor/widgets/inspector/properties/inspector_popout.dart';
import 'package:rive_editor/widgets/inspector/properties/inspector_popout_title.dart';
import 'package:rive_editor/widgets/inspector/properties/inspector_radio_button.dart';
import 'package:rive_editor/widgets/ui_strings.dart';
import 'package:rive_core/draw_target.dart';

/// Uses the InspectorPopoutComponent to build a row in the inspector for
/// editing a clip on a shape.
class PropertyDrawTarget extends StatelessWidget {
  final DrawTarget target;
  final bool isActive;
  final VoidCallback activate;
  final VoidCallback pickTarget;
  const PropertyDrawTarget({
    this.target,
    this.isActive,
    this.activate,
    this.pickTarget,
    Key key,
  }) : super(key: key);

  void _remove() {
    target.remove();
    target.context.captureJournalEntry();
  }

  @override
  Widget build(BuildContext context) {
    var theme = RiveTheme.of(context);
    var uiStrings = UIStrings.of(context);

    return InspectorPopout(
      padding: InspectorPopout.defaultPadding.copyWith(bottom: 2),
      contentBuilder: (_) => Row(
        children: [
          Expanded(
            child: CoreTextField(
              objects: [target],
              propertyKey: ComponentBase.namePropertyKey,
              converter: StringValueConverter.instance,
            ),
          ),
          const SizedBox(width: 15),
          InspectorRadioButton(
            select: activate,
            isSelected: isActive,
          ),
          const SizedBox(width: 5),
          TintedIconButton(
            onPress: _remove,
            icon: PackedIcon.delete,
          ),
        ],
      ),
      popupBuilder: (context) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const InspectorPopoutTitle(titleKey: 'draw_order_rule'),
            const SizedBox(height: 20),
            Row(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Name',
                  style: theme.textStyles.inspectorPropertyLabel,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: CoreTextField(
                    objects: [target],
                    propertyKey: ComponentBase.namePropertyKey,
                    converter: StringValueConverter.instance,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Text(
                  uiStrings.withKey('draw_order'),
                  style:
                      RiveTheme.of(context).textStyles.inspectorPropertyLabel,
                ),
                const SizedBox(width: 20),
                CoreComboBox(
                  sizing: ComboSizing.expanded,
                  objects: [target],
                  propertyKey: DrawTargetBase.placementValuePropertyKey,
                  options: DrawTargetPlacement.values,
                  toLabel: (DrawTargetPlacement placement) {
                    switch (placement) {
                      case DrawTargetPlacement.before:
                        return uiStrings.withKey('above_target');
                      case DrawTargetPlacement.after:
                        return uiStrings.withKey('below_target');
                    }
                    return '-';
                  },
                  toCoreValue: (DrawTargetPlacement value) => value.index,
                  fromCoreValue: (int value) =>
                      DrawTargetPlacement.values[value],
                ),
              ],
            ),
            const SizedBox(height: 20),
            InspectorPillButton(
              textColor: theme.colors.inspectorTextColor,
              icon: PackedIcon.target,
              label: target?.drawable?.name ?? uiStrings.withKey('target'),
              press: pickTarget,
            )
          ],
        ),
      ),
    );
  }
}
