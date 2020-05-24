import 'package:flutter/material.dart';
import 'package:rive_core/runtime_exporter.dart';
import 'package:rive_editor/platform/file_save.dart';
import 'package:rive_editor/rive/alerts/simple_alert.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/theme.dart';
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
        color: isHovered
            ? RiveThemeData().colors.toolbarButtonHover
            : RiveThemeData().colors.toolbarButton,
        icon: 'tool-export',
      ),
      width: 206,
      contextItemsBuilder: (context) => [
        PopupContextItem(
          'Download for Runtime',
          icon: 'download',
          select: () async {
            // Get the active file.
            var activeFile = ActiveFile.find(context);
            // Instance the exporter with some file meta data.
            var exporter = RuntimeExporter(
              core: activeFile.core,
              info: RuntimeFileInfo(
                fileId: activeFile.fileId,
                ownerId: activeFile.ownerId,
              ),
            );
            // Perform the export.
            var bytes = exporter.export();
            // Save it (desktop will popup a file dialog, web will simply
            // download it with the provided name).
            var filename =
                activeFile.name.value.toLowerCase().replaceAll(' ', '_');
            if (await FileSave.save('$filename.riv', bytes)) {
              activeFile.addAlert(
                SimpleAlert('File exported.'),
              );
            } else {
              activeFile.addAlert(
                SimpleAlert('Export canceled.'),
              );
            }
          },
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
