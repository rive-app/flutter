import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/inspector/properties/inspector_popout.dart';
import 'package:rive_editor/widgets/inspector/properties/inspector_popout_title.dart';
import 'package:rive_editor/widgets/inspector/properties/inspector_radio_button.dart';
import 'package:rive_editor/widgets/inspector/properties/inspector_text_field.dart';
import 'package:rive_editor/widgets/ui_strings.dart';

/// Uses the InspectorPopoutComponent to build a row in the inspector for
/// editing a clip on a shape.
class PropertyNormalDraw extends StatelessWidget {
  final bool isActive;
  final VoidCallback activate;
  const PropertyNormalDraw({
    this.isActive,
    this.activate,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var theme = RiveTheme.of(context);
    var uiStrings = UIStrings.of(context);

    return InspectorPopout(
      padding: InspectorPopout.defaultPadding.copyWith(bottom: 2),
      contentBuilder: (_) => Row(
        children: [
          Expanded(
            child:
                Text('Normal', style: theme.textStyles.inspectorPropertyLabel),
          ),
          InspectorRadioButton(
            select: activate,
            isSelected: isActive,
          ),
          const SizedBox(width: 30),
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
                  child: InspectorTextField(
                    value: null,
                    converter: null,
                    disabledText: uiStrings.withKey('normal_draw_rule'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              uiStrings.withKey('normal_draw_rule_desc'),
              style: theme.textStyles.inspectorDescription,
            ),
          ],
        ),
      ),
    );
  }
}
