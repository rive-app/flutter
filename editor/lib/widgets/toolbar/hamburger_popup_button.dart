import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/rive_popup_button.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

class HamburgerPopupButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RivePopupButton(
      showChevron: false,
      iconBuilder: (context, rive, isHovered) => TintedIcon(
        color:
            isHovered ? Colors.white : const Color.fromRGBO(140, 140, 140, 1),
        icon: 'tool-menu',
      ),
    );
  }
}
