import 'package:flutter/material.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';
import 'package:rive_editor/widgets/ui_strings.dart';

/// Default title styling to display in the popout for the inspector. Includes
/// an options icon.
class InspectorPopoutTitle extends StatelessWidget {
  final String titleKey;

  const InspectorPopoutTitle({
    Key key,
    this.titleKey,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    var theme = RiveTheme.of(context);
    return Row(
      children: [
        TintedIcon(
          icon: PackedIcon.options,
          color: theme.colors.toolbarButton,
        ),
        const SizedBox(width: 10),
        Text(
          UIStrings.of(context).withKey(titleKey),
          style: theme.textStyles.inspectorSectionHeader,
        ),
      ],
    );
  }
}
