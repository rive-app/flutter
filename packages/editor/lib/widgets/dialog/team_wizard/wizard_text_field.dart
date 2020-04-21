import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

class WizardTextFormField extends StatelessWidget {
  final bool enabled;
  final String initialValue;
  final String hintText;
  final String errorText;
  final List<TextInputFormatter> inputFormatters;
  final InputDecoration inputDecoration;
  final void Function(String) onChanged;
  final double fontSize;
  final double errorFontSize;

  const WizardTextFormField(
      {this.enabled = true,
      this.fontSize = 13,
      this.errorFontSize = 13,
      this.initialValue,
      this.inputFormatters,
      this.onChanged,
      this.hintText,
      this.errorText,
      this.inputDecoration});

  @override
  Widget build(BuildContext context) {
    final styles = RiveTheme.of(context).textStyles;
    final colors = RiveTheme.of(context).colors;

    return TextFormField(
        enabled: enabled,
        textAlign: TextAlign.left,
        textAlignVertical: TextAlignVertical.center,
        style: styles.fileGreyTextLarge.copyWith(fontSize: fontSize),
        initialValue: initialValue,
        inputFormatters: inputFormatters,
        cursorColor: colors.commonDarkGrey,
        decoration: InputDecoration(
          errorText: errorText,
          hintText: hintText,
          isDense: true,
          filled: true,
          hoverColor: Colors.transparent,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.only(bottom: 3),
          hintStyle: styles.textFieldInputHint.copyWith(fontSize: fontSize),
          errorStyle: styles.textFieldInputValidationError
              .copyWith(fontSize: errorFontSize),
          errorBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                  color: styles.textFieldInputValidationError.color, width: 2)),
          enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: colors.inputUnderline, width: 2)),
          focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: colors.commonDarkGrey, width: 2)),
        ),
        onChanged: onChanged);
  }
}
