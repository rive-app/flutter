import 'package:flutter/widgets.dart';
import 'package:rive_editor/rive/editor_alert.dart';
import 'package:rive_editor/widgets/common/flat_icon_button.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

/// A simple alert message that expires after a few seconds.
class ClickAlert extends EditorAlert {
  final String label;
  final String buttonLabel;
  final VoidCallback callback;
  @override
  bool dismissOnPress = false;

  ClickAlert(this.label, this.buttonLabel, this.callback);

  @override
  Widget build(BuildContext context) {
    var theme = RiveTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(5),
      width: 756,
      decoration: BoxDecoration(
        color: theme.colors.globalMessageBackground,
        borderRadius: const BorderRadius.all(
          Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Expanded(
              child: Padding(
            padding: const EdgeInsets.all(7.0),
            child: Text(label, style: theme.textStyles.popupText),
          )),
          FlatIconButton(
            label: buttonLabel,
            color: theme.colors.commonDarkGrey,
            textColor: theme.colors.getWhite,
            onTap: () => {callback()},
          )
        ],
      ),
    );
  }
}
