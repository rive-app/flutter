import 'package:flutter/material.dart';
import 'package:rive_api/files.dart';
import 'package:rive_editor/rive/file_browser/file_browser.dart';
import 'package:rive_editor/widgets/common/combo_box.dart';
import 'package:rive_editor/widgets/common/tinted_icon_button.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/popup/popup.dart';
import 'package:rive_editor/widgets/popup/popup_button.dart';
import 'package:rive_editor/widgets/popup/tooltip_button.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

class TopNav extends StatelessWidget {
  final FileBrowser fileBrowser;

  const TopNav(this.fileBrowser, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final riveColors = RiveTheme.of(context).colors;

    return Column(
      children: [
        Row(
          children: [
            PopupButton<PopupContextItem>(
              builder: (popupContext) {
                return Container(
                  width: 29,
                  height: 29,
                  decoration: BoxDecoration(
                      color: riveColors.commonDarkGrey, shape: BoxShape.circle),
                  child: Center(
                    child: SizedBox(
                      child: TintedIcon(color: Colors.white, icon: 'add'),
                    ),
                  ),
                );
              },
              itemBuilder: (popupContext, item, isHovered) =>
                  item.itemBuilder(popupContext, isHovered),
              items: [
                PopupContextItem('New File', select: fileBrowser.createFile),
                PopupContextItem('New Folder', select: () {
                  print('Create Folder!');
                })
              ],
            ),
            // Buttons padding.
            const SizedBox(width: 10),
            TintedIconButton(
              onPress: () {/** TODO: */},
              icon: 'user',
              backgroundHover: riveColors.fileBackgroundLightGrey,
              iconHover: riveColors.fileBackgroundDarkGrey,
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              tip: const Tip(label: 'Your Profile'),
            ),
            TintedIconButton(
              onPress: () {/** TODO: */},
              icon: 'settings',
              backgroundHover: riveColors.fileBackgroundLightGrey,
              iconHover: riveColors.fileBackgroundDarkGrey,
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              tip: const Tip(label: 'Settings'),
            ),
            const Spacer(), // Fill up the row to show ComboBox at the end.
            ValueListenableBuilder<RiveFileSortOption>(
              valueListenable: fileBrowser.selectedSortOption,
              builder: (sortBoxContext, sortOption, _) =>
                  ComboBox<RiveFileSortOption>(
                popupWidth: 100,
                sizing: ComboSizing.collapsed,
                underline: false,
                valueColor: riveColors.toolbarButton,
                options: fileBrowser.sortOptions.value,
                value: sortOption,
                toLabel: (option) => option.name,
                change: (option) =>
                    fileBrowser.loadFileList(sortOption: option),
              ),
            ),
            const SizedBox(width: 5), // Small padding before the end.
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 18.0),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Container(
                  color: riveColors.fileLineGrey,
                  height: 1,
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}
