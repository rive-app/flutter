import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/popup/context_popup.dart';
import 'package:rive_editor/widgets/popup/modal_popup.dart';
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
      width: 267,
      contextItems: [
        PopupContextItem("File Name",
            widgetBuilder: (context) => Container(
                  width: 125,
                  child: Center(
                    child: TextFormField(
                      initialValue: RiveContext.of(context).file.value.name,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.fromLTRB(0, 6, 0, 6),
                        enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                width: 2,
                                color: RiveTheme.of(context).colors.separator)),
                        focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                width: 2,
                                color: RiveTheme.of(context)
                                    .colors
                                    .separatorActive)),
                        hintText: 'New File Name',
                        hintStyle:
                            RiveTheme.of(context).textStyles.popupShortcutText,
                      ),
                      style: RiveTheme.of(context).textStyles.popupShortcutText,
                    ),
                  ),
                ),
            select: () {},
            dismissOnSelect: false),
        PopupContextItem(
          "Team Permissions",
          select: () => _showModal(context, (_) => Container()),
        ),
        PopupContextItem(
          "Revision History",
          select: () => _showModal(context, (_) => Container()),
        ),
        PopupContextItem.separator(),
        PopupContextItem(
          "New File",
          icon: 'add',
        ),
        PopupContextItem(
          "New Folder",
          icon: 'popup-folder',
        ),
        PopupContextItem.separator(),
        PopupContextItem(
          "Manual",
        ),
        PopupContextItem(
          "Shortcuts",
        ),
        PopupContextItem(
          "Report an Issue",
        ),
        PopupContextItem(
          "Request a Feature",
        ),
        PopupContextItem(
          "Work with Us!",
        ),
      ],
    );
  }

  void _showModal(BuildContext context, WidgetBuilder builder) {
    ModalPopup(
      builder: builder,
      size: const Size(750, 629),
      elevation: 20,
    ).show(context);
  }
}
