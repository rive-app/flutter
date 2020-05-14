import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/models/team_role.dart';
import 'package:rive_api/plumber.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:rive_editor/rive/file_browser/browser_tree_controller.dart';
import 'package:rive_editor/rive/stage/items/stage_cursor.dart';
import 'package:rive_editor/widgets/common/tinted_icon_button.dart';
import 'package:rive_editor/widgets/dialog/team_settings/settings_panel.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/popup/context_popup.dart';
import 'package:rive_editor/widgets/popup/popup_button.dart';
import 'package:rive_editor/widgets/popup/popup_direction.dart';
import 'package:rive_editor/widgets/popup/tip.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';
import 'package:rive_editor/widgets/toolbar/connected_users.dart';
import 'package:rive_editor/widgets/tree_view/drop_item_background.dart';
import 'package:rive_editor/widgets/tree_view/tree_expander.dart';
import 'package:tree_widget/flat_tree_item.dart';
import 'package:tree_widget/tree_style.dart';
import 'package:tree_widget/tree_widget.dart';

class FolderTreeView extends StatelessWidget {
  final FolderTreeItemController controller;
  final TreeStyle style;

  const FolderTreeView({
    @required this.controller,
    this.style,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = RiveTheme.of(context).colors;

    return TreeView<FolderTreeItem>(
      style: style,
      controller: controller,
      expanderBuilder: (context, item, style) => StreamBuilder<bool>(
        stream: item.data.selectedStream,
        builder: (context, selectedStream) => Container(
          child: Center(
            child: TreeExpander(
              key: item.key,
              iconColor: (selectedStream.hasData && selectedStream.data)
                  ? Colors.white
                  : colors.fileUnselectedFolderIcon,
              isExpanded: item.isExpanded,
            ),
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: (selectedStream.hasData && selectedStream.data)
                  ? colors.selectedTreeLines
                  : colors.filesTreeStroke,
              width: 1.0,
              style: BorderStyle.solid,
            ),
            borderRadius: const BorderRadius.all(
              Radius.circular(7.5),
            ),
          ),
        ),
      ),
      iconBuilder: (context, item, style) => StreamBuilder<bool>(
        stream: item.data.selectedStream,
        builder: (context, selectedStream) => Container(
          width: 20,
          height: 20,
          child: Center(
            child: FolderTreeIcon(
              owner: item.data.owner,
              icon: (item.data.folder != null && item.data.folder.id == 0)
                  ? 'trash'
                  : 'folder',
              iconColor: (selectedStream.hasData && selectedStream.data)
                  ? colors.fileSelectedFolderIcon
                  : colors.fileUnselectedFolderIcon,
            ),
          ),
        ),
      ),
      extraBuilder: (context, item, index) => Container(),
      backgroundBuilder: (context, item, style) {
        return StreamBuilder<bool>(
            stream: item.data.selectedStream,
            builder: (context, selectedStream) {
              bool selected = selectedStream.hasData && selectedStream.data;
              return StreamBuilder<bool>(
                  stream: item.data.hoverStream,
                  builder: (context, hoverStream) {
                    bool hovered = hoverStream.hasData && hoverStream.data;
                    var _selectionState = SelectionState.none;
                    if (selected) {
                      _selectionState = SelectionState.selected;
                    } else if (hovered) {
                      _selectionState = SelectionState.hovered;
                    }
                    return DropItemBackground(DropState.none, _selectionState);
                  });
            });
      },
      itemBuilder: (context, item, style) => StreamBuilder<bool>(
        stream: item.data.selectedStream,
        builder: (context, selectedStream) => Expanded(
          child: Row(children: [
            Expanded(
              child: Container(
                child: IgnorePointer(
                  child: Text(
                    item.data.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: (selectedStream.hasData && selectedStream.data)
                          ? Colors.white
                          : colors.fileTreeText,
                    ),
                  ),
                ),
              ),
            ),
            if (item.data.owner is Me ||
                (item.data.owner is Team &&
                    canEditTeam((item.data.owner as Team).permission)))
              TintedIconButton(
                onPress: () async {
                  await showSettings(item.data.owner, context: context);
                },
                icon: 'settings-small',
                color: (selectedStream.hasData && selectedStream.data)
                    ? colors.fileSelectedFolderIcon
                    : colors.fileUnselectedFolderIcon,
                iconHover: colors.fileBackgroundDarkGrey,
                tip: const Tip(label: 'Settings'),
              ),
            if (item.data.owner != null)
              AddFileFolderButton(
                item.data.owner,
                (selectedStream.hasData && selectedStream.data),
              )
          ]),
        ),
      ),
    );
  }
}

class FolderTreeIcon extends StatelessWidget {
  const FolderTreeIcon({
    this.owner,
    this.iconColor,
    this.size = const Size(15, 15),
    this.icon = 'folder',
    Key key,
  }) : super(key: key);

  final Owner owner;
  final Size size;
  final String icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    var colors = RiveTheme.of(context).colors;

    if (owner == null) {
      return Center(
          child: SizedBox(
        width: size.width,
        height: size.height,
        child: TintedIcon(
            icon: icon,
            color: (iconColor == null)
                ? colors.fileUnselectedFolderIcon
                : iconColor),
      ));
    } else {
      return AvatarView(
        diameter: 15,
        padding: 0,
        borderWidth: 0,
        imageUrl: owner.avatarUrl,
        name: owner.displayName,
        color: StageCursor.colorFromPalette(owner.ownerId),
      );
    }
  }
}

class AddFileFolderButton extends StatelessWidget {
  final Owner owner;
  // its the magic 'your files folder'
  final folderId = 1;
  final bool selected;

  const AddFileFolderButton(
    this.owner,
    this.selected, {
    Key key,
  }) : super(key: key);

  void updateCurrentDirectory() {
    var currentDirectory = Plumber().peek<CurrentDirectory>();
    if (currentDirectory.owner == owner && currentDirectory.folderId == 1) {
      Plumber().message(currentDirectory);
    }
  }

  @override
  Widget build(BuildContext context) {
    var colors = RiveTheme.of(context).colors;

    return PopupButton<PopupContextItem>(
      direction: PopupDirection.rightToCenter,
      builder: (popupContext) {
        return TintedIconButton(
          icon: 'add',
          color: selected
              ? colors.fileSelectedFolderIcon
              : colors.fileUnselectedFolderIcon,
          iconHover: colors.fileSelectedFolderIcon,
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
            updateCurrentDirectory();
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
            updateCurrentDirectory();
          },
        )
      ],
    );
  }
}
