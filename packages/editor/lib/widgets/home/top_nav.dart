import 'package:flutter/material.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/files.dart';
import 'package:rive_api/models/owner.dart';
import 'package:rive_api/models/team.dart';
import 'package:rive_editor/rive/file_browser/file_browser.dart';
import 'package:rive_editor/widgets/common/combo_box.dart';
import 'package:rive_editor/widgets/common/tinted_icon_button.dart';
import 'package:rive_editor/widgets/common/underline.dart';
import 'package:rive_editor/widgets/dialog/rive_dialog.dart';
import 'package:rive_editor/widgets/dialog/team_settings/settings_panel.dart';
import 'package:rive_editor/widgets/dialog/team_settings/team_members_panel.dart';
import 'package:rive_editor/widgets/dialog/team_settings/team_settings_panel.dart';
import 'package:rive_editor/widgets/dialog/team_wizard/team_wizard.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/popup/popup.dart';
import 'package:rive_editor/widgets/popup/popup_button.dart';
import 'package:rive_editor/widgets/popup/popup_direction.dart';
import 'package:rive_editor/widgets/popup/tip.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

class TopNav extends StatelessWidget {
  final FileBrowser fileBrowser;

  const TopNav(this.fileBrowser, {Key key}) : super(key: key);

  List<SettingsScreen> _getScreens(
      bool isTeam, RiveApi api, RiveOwner currentOwner) {
    if (isTeam) {
      return [
        SettingsScreen('Team Settings', TeamSettings()),
        SettingsScreen(
            'Members', TeamMembers(api: api, owner: currentOwner as RiveTeam)),
      ];
    } else {
      return [SettingsScreen('Profile', Container())];
    }
  }

  Widget _navControls(BuildContext context) {
    final riveColors = RiveTheme.of(context).colors;
    final api = RiveContext.of(context).api;

    return Row(
      children: [
        const Spacer(),
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
        const SizedBox(width: 15),
        TintedIconButton(
          onPress: () {/** TODO: */},
          icon: 'user',
          backgroundHover: riveColors.fileBackgroundLightGrey,
          iconHover: riveColors.fileBackgroundDarkGrey,
          tip: const Tip(label: 'Your Profile'),
        ),
        const SizedBox(width: 12),
        TintedIconButton(
          onPress: () {
            // Be sure to fetch the current selection.
            final currentOwner = RiveContext.of(context).currentOwner;
            final isTeam = currentOwner is RiveTeam;
            showRiveDialog<void>(
                context: context,
                builder: (context) => SettingsPanel(
                    isTeam: isTeam,
                    screens: _getScreens(isTeam, api, currentOwner)));
          },
          icon: 'settings',
          backgroundHover: riveColors.fileBackgroundLightGrey,
          iconHover: riveColors.fileBackgroundDarkGrey,
          tip: const Tip(label: 'Settings'),
        ),
        const SizedBox(width: 12),
        PopupButton<PopupContextItem>(
          direction: PopupDirection.bottomToLeft,
          builder: (popupContext) {
            return Container(
              width: 29,
              height: 29,
              decoration: BoxDecoration(
                  color: riveColors.commonDarkGrey, shape: BoxShape.circle),
              child: const Center(
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
            PopupContextItem('New Folder', select: () {}),
            PopupContextItem.separator(),
            PopupContextItem(
              'New Team',
              select: () => showTeamWizard<void>(context: context),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final riveColors = RiveTheme.of(context).colors;

    return Underline(
      color: riveColors.fileLineGrey,
      child: _navControls(context),
      offset: 18,
      thickness: 1,
    );
  }
}
