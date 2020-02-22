import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/popup/context_popup.dart';
import 'package:rive_editor/widgets/popup/modal_popup.dart';
import 'package:rive_editor/widgets/rive_popup_button.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

/// The popup button showed in the toolbar allowing the user access other
/// options for the current file, such as Downloading a Rive file for runtime
/// use, sharing the file with the community, using the cloud renderer, and
/// entering presentation mode.
class SharePopupButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RivePopupButton(
      showChevron: true,
      iconBuilder: (context, rive, isHovered) => TintedIcon(
        color:
            isHovered ? Colors.white : const Color(0xFF8C8C8C),
        icon: 'tool-export',
      ),
      width: 200,
      contextItems: [
        PopupContextItem(
          'Download for Runtime',
          icon: 'download',
          select: () => _showModal(context, (_) => Container()),
        ),
        PopupContextItem(
          'Publish to Community',
          icon: 'popup-community',
          select: () => _showModal(context, (_) => Container()),
        ),
        PopupContextItem(
          'Presentation Mode',
          icon: 'popup-presentation',
          select: () => _showModal(context, (_) => Container()),
        ),
        PopupContextItem(
          'Cloud Renderer',
          icon: 'popup-server',
          select: () => _showModal(context, (_) => Container()),
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
