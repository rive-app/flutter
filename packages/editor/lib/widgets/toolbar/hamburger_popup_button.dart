import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/common/converters/string_notifier_value_converter.dart';
import 'package:rive_editor/widgets/inspector/properties/inspector_text_field.dart';
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
      showChevron: false,
      iconBuilder: (context, rive, isHovered) => TintedIcon(
        color: isHovered
            ? RiveThemeData().colors.popupIconHover
            : RiveThemeData().colors.popupIcon,
        icon: 'tool-menu',
      ),
      width: 267,
      contextItemsBuilder: (context) => [
        PopupContextItem('File Name',
            child: SizedBox(
              width: 125,
              child: InspectorTextField<ValueNotifier<String>>(
                value: RiveContext.of(context).file.value.name,
                converter: StringNotifierValueConverter(
                    RiveContext.of(context).file.value.name),
                change: (_) {},
                completeChange: (s) {
                  RiveContext.of(context).file.value.changeFileName(s.value);
                },
              ),
            ),
            select: () {},
            dismissOnSelect: false),
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
          'New File',
          icon: 'add',
        ),
        PopupContextItem(
          'New Folder',
          icon: 'popup-folder',
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
