import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

class SettingsTextField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final String label;
  final String hint;
  final String initialValue;

  const SettingsTextField(
      {@required this.label, this.hint, this.onChanged, this.initialValue});

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    final colors = theme.colors;
    final textStyles = theme.textStyles;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(label,
            style: textStyles.hierarchyTabHovered
                .copyWith(fontSize: 13, letterSpacing: 0)),
        const SizedBox(height: 11),
        TextFormField(
            onChanged: onChanged,
            cursorColor: colors.commonDarkGrey,
            textAlign: TextAlign.left,
            initialValue: initialValue,
            keyboardType: TextInputType.multiline,
            minLines: 1,
            maxLines: 5,
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle: textStyles.textFieldInputHint.copyWith(fontSize: 13),
              contentPadding: const EdgeInsets.only(bottom: 2),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: colors.input, width: 2),
              ),
              focusedBorder: UnderlineInputBorder(
                  borderSide:
                      BorderSide(color: colors.commonDarkGrey, width: 2)),
            ),
            style: textStyles.fileGreyTextLarge
                .copyWith(fontSize: 13, letterSpacing: 0)),
      ],
    );
  }
}
