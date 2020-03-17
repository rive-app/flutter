import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

/// Default title styling to display in the popout for the inspector. Includes
/// an options icon.
class InspectorPopoutTitle extends StatelessWidget {
  final String title;

  const InspectorPopoutTitle({
    Key key,
    this.title,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    var theme = RiveTheme.of(context);
    return Row(
      children: [
        TintedIcon(
          icon: 'options',
          color: theme.colors.toolbarButton,
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: theme.textStyles.inspectorPropertySubLabel,
        ),
      ],
    );
  }
}
