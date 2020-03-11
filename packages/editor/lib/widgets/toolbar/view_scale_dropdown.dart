import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

class ViewScaleDropdown extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DropdownButton<double>(
      // N.B. Luigi added this as otherwise it would constantly try to steal
      // focus from other FocusNodes. Not sure if this is a Flutter bug or more
      // likely there's some fundamental focus related logic I'm
      // misunderstanding, but this made the focus management for action
      // binding, popup navigation, and combo type-ahead deterministic.
      focusNode: FocusNode(skipTraversal: true),
      value: 1,
      items: [
        DropdownMenuItem(
          value: 1,
          child: Text(
            '100%',
            style: RiveTheme.of(context).textStyles.popupText,
          ),
        ),
      ],
      underline: Container(),
      onChanged: (val) {},
    );
  }
}
