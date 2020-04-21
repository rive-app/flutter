import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive_editor/widgets/theme.dart';

TextFormField getTextFormField({
  @required TextStyle style,
  bool enabled = true,
  String initialValue,
  List<TextInputFormatter> inputFormatters,
  InputDecoration inputDecoration,
  void Function(String) onChanged,
}) {
  return TextFormField(
      enabled: enabled,
      textAlign: TextAlign.left,
      textAlignVertical: TextAlignVertical.center,
      style: style,
      initialValue: initialValue,
      inputFormatters: inputFormatters,
      decoration: inputDecoration,
      onChanged: onChanged);
}

InputDecoration getInputDecoration({
  @required TextStyle hintStyle,
  @required TextStyle errorStyle,
  @required RiveColors riveColors,
  String hintText,
  String errorText,
}) {
  return InputDecoration(
    errorText: errorText,
    hintText: hintText,
    isDense: true,
    enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: riveColors.inputUnderline, width: 2)),
    hintStyle: hintStyle,
    errorStyle: errorStyle,
    errorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: errorStyle.color, width: 2)),
    contentPadding: const EdgeInsets.only(bottom: 3),
    filled: true,
    hoverColor: Colors.transparent,
    fillColor: Colors.transparent,
  );
}
