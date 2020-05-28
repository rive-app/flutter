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

  bool isSelected(AsyncSnapshot<bool> selectedStream) =>
      selectedStream.hasData && selectedStream.data;

  _newFileButton(BuildContext context, FolderTreeItem itemData,
      AsyncSnapshot<bool> selectedStream) {
    final owner = itemData.owner;
    if (owner == null) {
      return const SizedBox();
    }

    // its the magic 'your files folder'
    const yourFilesFolderId = 1;
    final colors = RiveTheme.of(context).colors;

    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: TintedIconButton(
        onPress: () async {
          final createdFile = (owner is Team)
              ? await FileManager().createFile(yourFilesFolderId, owner.ownerId)
              : await FileManager().createFile(yourFilesFolderId);

          // Update current directory.
          var currentDirectory = Plumber().peek<CurrentDirectory>();
          if (currentDirectory.owner == owner && currentDirectory.folderId == 1) {
            Plumber().message(currentDirectory);
          }

          RiveContext.of(context).open(
            createdFile.fileOwnerId,
            createdFile.id,
            createdFile.name,
          );
        },
        icon: 'add',
        color: isSelected(selectedStream)
            ? colors.fileSelectedFolderIcon
            : colors.fileUnselectedFolderIcon,
        iconHover: Colors.green,
        // iconHover: colors.fileBackgroundDarkGrey,
        backgroundHover: Colors.transparent,
        tip: const Tip(
          label: 'New File',
        ),
        onHover: (isHovered) => itemData.hover = isHovered,
      ),
    );
  }

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
              iconColor: isSelected(selectedStream)
                  ? Colors.white
                  : colors.fileUnselectedFolderIcon,
              isExpanded: item.isExpanded,
            ),
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected(selectedStream)
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
        builder: (context, selectedStream) => SizedBox(
          width: 20,
          height: 20,
          child: Center(
            child: FolderTreeIcon(
              owner: item.data.owner,
              icon: item.data.folder?.id == 0 ? 'trash' : 'folder',
              iconColor: isSelected(selectedStream)
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
                      color: isSelected(selectedStream)
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
                color: isSelected(selectedStream)
                    ? colors.fileSelectedFolderIcon
                    : colors.fileUnselectedFolderIcon,
                iconHover: Colors.green,
                // iconHover: colors.fileBackgroundDarkGrey,
                backgroundHover: Colors.transparent,
                tip: const Tip(
                  label: 'Settings',
                ),
                onHover: (isHovered) => item.data.hover = isHovered,
              ),
            _newFileButton(context, item.data, selectedStream),
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
