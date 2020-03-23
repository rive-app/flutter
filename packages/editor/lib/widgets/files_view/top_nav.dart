import 'package:flutter/material.dart';
import 'package:rive_api/files.dart';
import 'package:rive_editor/rive/file_browser/file_browser.dart';
import 'package:rive_editor/widgets/common/combo_box.dart';
import 'package:rive_editor/widgets/common/tinted_icon_button.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/path_widget.dart';
import 'package:rive_editor/widgets/popup/popup.dart';
import 'package:rive_editor/widgets/popup/popup_button.dart';
import 'package:rive_editor/widgets/popup/tooltip_item.dart';

class TopNav extends StatelessWidget {
  final FileBrowser fileBrowser;

  const TopNav(this.fileBrowser, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final riveColors = RiveTheme.of(context).colors;

    return Column(children: [
      Row(children: [
        PopupButton<PopupContextItem>(
          builder: (context) {
            final plusPath = Path()
              ..addRect(const Rect.fromLTWH(13 / 2 - 1.37 / 2, -13, 1.37, 13))
              ..addRect(const Rect.fromLTWH(0, -13 / 2 - 1.37 / 2, 13, 1.37));

            return Container(
                width: 29,
                height: 29,
                decoration: const BoxDecoration(
                    color: Color.fromRGBO(51, 51, 51, 1),
                    shape: BoxShape.circle),
                child: Center(
                  child: Container(
                      child: PathWidget(
                          path: plusPath,
                          paint: Paint()
                            ..color = Colors.white
                            ..style = PaintingStyle.fill
                            ..isAntiAlias = true)),
                ));
          },
          itemBuilder: (context, item, isHovered) =>
              item.itemBuilder(context, isHovered),
          items: [
            PopupContextItem('New File', select: fileBrowser.createFile),
            PopupContextItem('New Folder', select: () {
              print('Create Folder!');
            })
          ],
        ),
        Container(
          // Buttons padding.
          width: 10,
        ),
        // Wrap in LayoutBuilder to provide the child context for the
        // ListPopup to show up.
        LayoutBuilder(builder: (userContext, constraints) {
          return TintedIconButton(
            onPress: () {/** TODO: */},
            tooltipItems: [TooltipItem('Your Profile')],
            tooltipWidth: 96,
            icon: 'user',
            backgroundHover: const Color(0xFFF1F1F1),
            iconHover: const Color(0xFF666666),
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          );
        }),
        // Wrap in LayoutBuilder to provide the child context for the
        // ListPopup to show up.
        LayoutBuilder(builder: (settingsContext, constraints) {
          return TintedIconButton(
            onPress: () {/** TODO: */},
            tooltipItems: [TooltipItem('Settings')],
            tooltipWidth: 76,
            icon: 'settings',
            backgroundHover: const Color(0xFFF1F1F1),
            iconHover: const Color(0xFF666666),
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          );
        }),
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
            change: (option) => fileBrowser.loadFileList(sortOption: option),
          ),
        ),
        Container(width: 5), // Small padding before the end.
      ]),
      Padding(
          padding: const EdgeInsets.only(top: 18.0),
          child: Row(children: <Widget>[
            Expanded(
              child: Container(
                color: riveColors.fileLineGrey,
                height: 1,
              ),
            )
          ])),
    ]);
  }
}
