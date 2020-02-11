import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/rive_popup_button.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

class TransformPopupButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RivePopupButton(
      iconBuilder: (context, rive) => const TintedIcon(
          color: Color.fromRGBO(140, 140, 140, 1), icon: 'tool-auto'),
    );
  }
}
