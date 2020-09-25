import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rive_editor/external_url.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/widgets/common/converters/string_value_converter.dart';
import 'package:rive_editor/widgets/common/value_listenable_text_field.dart';
import 'package:rive_editor/widgets/popup/popup_direction.dart';
import 'package:rive_editor/widgets/theme.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/popup/context_popup.dart';
import 'package:rive_editor/widgets/rive_popup_button.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';
import 'package:rive_editor/widgets/ui_strings.dart';

class HamburgerPopupButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RivePopupButton(
      direction: PopupDirection.bottomToRight,
      // Intentionally leave fallbacks empty, we only want bottomToRight on the
      // hamburger popup.
      fallbackDirections: const [],
      showChevron: false,
      iconBuilder: (context, rive, isHovered) => TintedIcon(
        color: isHovered
            ? RiveThemeData().colors.popupIconHover
            : RiveThemeData().colors.popupIcon,
        icon: PackedIcon.toolMenu,
        position: TintedIconPosition.round,
      ),
      width: 267,
      contextItemsBuilder: (context) => [
        PopupContextItem.focusable(
          UIStrings.of(context).withKey('file_name'),
          child: (focus, key) {
            // Focus this input right away when the popup displays.
            focus.requestFocus();
            return SizedBox(
              width: 75,
              child: ValueListenableTextField(
                key: key,
                focusNode: focus,
                listenable: ActiveFile.of(context).name,
                converter: StringValueConverter.instance,
                // Required by text field, otherwise won't show up.
                change: (String s) {},
                completeChange: (String s) {
                  RiveContext.of(context).file.value.changeFileName(s);
                },
                // change: (double value) => file.stage.zoomLevel = value,
              ),
            );
          },
        ),
        PopupContextItem(
          UIStrings.of(context).withKey('revision_history'),
          select: () => ActiveFile.find(context).showRevisionHistory(),
        ),
        PopupContextItem.separator(),
        // TODO: while this fixes this timing problem, it's pretty ugly. Need to
        // implement a way to call url launcher once the popup has tidied itself
        // up and closed
        PopupContextItem(
          UIStrings.of(context).withKey('help_center'),
          select: () => Future.delayed(
            const Duration(milliseconds: 100),
            launchHelpUrl,
          ),
        ),
        PopupContextItem(
          UIStrings.of(context).withKey('send_feedback'),
          select: () => Future.delayed(
            const Duration(milliseconds: 100),
            launchSupportUrl,
          ),
        ),
      ],
    );
  }
}
