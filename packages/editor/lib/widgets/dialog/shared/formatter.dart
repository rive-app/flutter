import 'package:flutter/services.dart';

class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final int newTextLength = newValue.text.length;
    int selectionIndex = newValue.selection.end;
    final StringBuffer newText = StringBuffer();
    int writeIndex = 0;
    if (newTextLength > 4) {
      newText.write(newValue.text.substring(0, 4));
      newText.write(' ');
      writeIndex += 4;
      selectionIndex += 1;
    }
    if (newTextLength > 8) {
      newText.write(newValue.text.substring(4, 8));
      newText.write(' ');
      writeIndex += 4;
      selectionIndex += 1;
    }
    if (newTextLength > 12) {
      newText.write(newValue.text.substring(8, 12));
      newText.write(' ');
      writeIndex += 4;
      selectionIndex += 1;
    }
    newText.write(newValue.text.substring(writeIndex));
    return TextEditingValue(
      text: newText.toString(),
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}

class DateTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final int newTextLength = newValue.text.length;
    int selectionIndex = newValue.selection.end;
    final StringBuffer newText = StringBuffer();
    int writeIndex = 0;
    if (newTextLength > 2) {
      newText.write(newValue.text.substring(0, 2));
      newText.write('/');
      writeIndex += 2;
      selectionIndex += 1;
    }
    newText.write(newValue.text.substring(writeIndex));
    return TextEditingValue(
      text: newText.toString(),
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}

class DateTextRegexCheck extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var regex = RegExp(r'^(0[1-9]*|1[012]*|$)/*\d*\d*');
    var match = regex.firstMatch(newValue.text);
    if (match != null && match.end == newValue.text.length) {
      return newValue;
    }
    return oldValue;
  }
}
