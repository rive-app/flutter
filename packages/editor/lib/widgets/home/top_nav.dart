import 'package:pedantic/pedantic.dart';
import 'package:flutter/material.dart';
import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/models/team_role.dart';
import 'package:rive_api/plumber.dart';
import 'package:rive_editor/rive/managers/folder_tree_manager.dart';
import 'package:rive_editor/widgets/common/tinted_icon_button.dart';
import 'package:rive_editor/widgets/common/underline.dart';
import 'package:rive_editor/widgets/dialog/team_settings/settings_panel.dart';
import 'package:rive_editor/widgets/dialog/team_wizard/team_wizard.dart';
import 'package:rive_editor/widgets/home/folder_tree.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/popup/popup.dart';
import 'package:rive_editor/widgets/popup/popup_button.dart';
import 'package:rive_editor/widgets/popup/popup_direction.dart';
import 'package:rive_editor/widgets/popup/tip.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

class TopNavStream extends StatelessWidget {
  final CurrentDirectory currentDirectory;

  Owner get owner => currentDirectory.owner;
  int get folderId => currentDirectory.folderId;

  const TopNavStream(this.currentDirectory, {Key key}) : super(key: key);

  Widget _navControls(BuildContext context) {
    final riveColors = RiveTheme.of(context).colors;
    final children = <Widget>[];
    if (owner != null) {
      children.add(SizedAvatar(
        url: owner.avatarUrl,
        size: const Size(30, 30),
        addBackground: true,
        icon: 'teams',
      ));
      children.add(const Padding(
        padding: EdgeInsets.only(right: 9),
      ));
    }
    children.add(Text(owner.displayName));
    children.add(const Spacer());

    if (owner is Me ||
        (owner is Team && canEditTeam((owner as Team).permission))) {
      children.add(const SizedBox(width: 12));
      children.add(TintedIconButton(
        onPress: () async {
          await showSettings(owner, context: context);
        },
        icon: 'settings',
        backgroundHover: riveColors.fileBackgroundLightGrey,
        iconHover: riveColors.fileBackgroundDarkGrey,
        tip: const Tip(label: 'Settings'),
      ));
    }
    children.add(const SizedBox(width: 12));
    children.add(PopupButton<PopupContextItem>(
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
      itemsBuilder: (context) => [
        PopupContextItem('New File', select: () async {
          if (owner is Team) {
            await FileManager().createFile(folderId, owner.ownerId);
          } else {
            await FileManager().createFile(folderId);
          }
          // TODO:
          // open file
          unawaited(FolderTreeManager().loadFolders(owner));
          Plumber().message(currentDirectory);
        }),
        PopupContextItem('New Folder', select: () async {
          if (owner is Team) {
            await FileManager().createFolder(folderId, owner.ownerId);
          } else {
            await FileManager().createFolder(folderId);
          }
          // NOTE: bit funky, feels like it'd be nice
          // to control both managers through one message
          // pretty sure we can do that if we back onto
          // a more generic FileManager
          unawaited(FolderTreeManager().loadFolders(owner));
          Plumber().message(currentDirectory);
        }),
        PopupContextItem.separator(),
        PopupContextItem(
          'New Team',
          select: () => showTeamWizard<void>(context: context),
        ),
      ],
    ));

    return Row(children: children);
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
