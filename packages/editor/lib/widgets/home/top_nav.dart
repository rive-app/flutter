import 'package:flutter/material.dart';
import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/plumber.dart';
import 'package:rive_editor/rive/stage/items/stage_cursor.dart';
import 'package:rive_editor/widgets/common/underline.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/popup/popup.dart';
import 'package:rive_editor/widgets/popup/popup_button.dart';
import 'package:rive_editor/widgets/popup/popup_direction.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';
import 'package:rive_editor/widgets/toolbar/connected_users.dart';

class TopNav extends StatelessWidget {
  final CurrentDirectory currentDirectory;

  Owner get owner => currentDirectory.owner;
  int get folderId => currentDirectory.folderId;

  const TopNav(this.currentDirectory, {Key key}) : super(key: key);

  Widget _navControls(BuildContext context, List<Folder> folders) {
    final riveColors = RiveTheme.of(context).colors;
    final children = <Widget>[];
    final currentFolder =
        folders.firstWhere((folder) => folder.id == currentDirectory.folderId);
    if (owner != null && currentFolder.id == 1) {
      children.add(
        AvatarView(
          diameter: 30,
          borderWidth: 0,
          padding: 0,
          imageUrl: owner.avatarUrl,
          name: owner.displayName,
          color: StageCursor.colorFromPalette(owner.ownerId),
        ),
      );
      children.add(const SizedBox(width: 9));
      children.add(Text(owner.displayName));
    } else {
      children.add(
        Center(
          child: SizedBox(
            width: 30,
            height: 30,
            child: GestureDetector(
              child: Container(
                decoration: BoxDecoration(
                  color: riveColors.fileBackgroundLightGrey,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: TintedIcon(
                    icon: 'back',
                    color: riveColors.inspectorTextColor,
                  ),
                ),
              ),
              // if the current folder has no parent, just take you back to the
              // magic folder nbr 1. (this deals with the Deleted folder
              // anomaly)
              onTap: () => Plumber().message(CurrentDirectory(
                  currentDirectory.owner, currentFolder.parent ?? 1)),
            ),
          ),
        ),
      );
      children.add(const SizedBox(width: 9));
      children.add(Text(currentFolder.name));
    }
    children.add(const Spacer());
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
        PopupContextItem(
          'New File',
          select: () async {
            if (owner is Team) {
              await FileManager().createFile(folderId, owner.ownerId);
            } else {
              await FileManager().createFile(folderId);
            }
            // TODO: open file
            FileManager().loadFolders(owner);
            Plumber().message(currentDirectory);
          },
        ),
        PopupContextItem(
          'New Folder',
          select: () async {
            if (owner is Team) {
              await FileManager().createFolder(folderId, owner.ownerId);
            } else {
              await FileManager().createFolder(folderId);
            }
            // NOTE: bit funky, feels like it'd be nice
            // to control both managers through one message
            // pretty sure we can do that if we back onto
            // a more generic FileManager
            FileManager().loadFolders(owner);
            Plumber().message(currentDirectory);
          },
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
      child: StreamBuilder<List<Folder>>(
        stream:
            Plumber().getStream<List<Folder>>(currentDirectory.owner.hashCode),
        builder: (context, snapshot) => snapshot.hasData == false
            ? const SizedBox()
            : _navControls(context, snapshot.data),
      ),
      thickness: 1,
    );
  }
}
