import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:rive_editor/rive/editor_alert.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

/// A simple alert message that expires after a few seconds.
class SimpleAlert extends EditorAlert {
  final String label;

  SimpleAlert(this.label) {
    Timer(const Duration(seconds: 3), dismiss);
  }

  @override
  Widget build(BuildContext context) {
    var theme = RiveTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      width: 756,
      decoration: BoxDecoration(
        color: theme.colors.panelBackgroundDarkGrey,
        borderRadius: const BorderRadius.all(
          Radius.circular(20),
        ),
      ),
      child: Text(label, style: theme.textStyles.popupText),
    );
  }
}
