import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/common/converters/string_value_converter.dart';
import 'package:rive_editor/widgets/common/value_listenable_text_field.dart';
import 'package:rive_editor/widgets/popup/popup_direction.dart';
import 'package:rive_editor/widgets/theme.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/popup/context_popup.dart';
import 'package:rive_editor/widgets/popup/modal_popup.dart';
import 'package:rive_editor/widgets/rive_popup_button.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

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
        icon: 'tool-menu',
      ),
      width: 267,
      contextItemsBuilder: (context) => [
        PopupContextItem.focusable(
          'File Name',
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
          'Team Permissions',
          select: () => _showModal(context, (_) => Container()),
        ),
        PopupContextItem(
          'Revision History',
          select: () => _showModal(context, (_) => Container()),
        ),
        PopupContextItem.separator(),
        PopupContextItem(
          'Manual',
        ),
        PopupContextItem(
          'Shortcuts',
        ),
        PopupContextItem(
          'Report an Issue',
        ),
        PopupContextItem(
          'Request a Feature',
        ),
        PopupContextItem(
          'Work with Us!',
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
