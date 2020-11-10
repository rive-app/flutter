import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/models/team_role.dart';
import 'package:rive_api/plumber.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/selectable_item.dart';
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

  @override
  Widget build(BuildContext context) {
    final colors = RiveTheme.of(context).colors;

    return TreeView<FolderTreeItem>(
      style: style,
      controller: controller,
      expanderBuilder: (context, item, _) => StreamBuilder<bool>(
          stream: item.data.selectedStream,
          builder: (context, selectedStream) => CircleTreeExpander(
                item: item,
                isSelected: isSelected(selectedStream),
              )),
      iconBuilder: (context, item, style) => StreamBuilder<bool>(
        stream: item.data.selectedStream,
        builder: (context, selectedStream) => SizedBox(
          width: 20,
          height: 20,
          child: Center(
            child: FolderTreeIcon(
              item: item.data,
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
            if (item.data.isRoot &&
                (item.data.owner is Me ||
                    (item.data.owner is Team &&
                        canEditTeam((item.data.owner as Team).permission))))
              FolderTreeItemButton(
                itemData: item.data,
                isSelected: isSelected(selectedStream),
                icon: PackedIcon.settingsSmall,
                tooltip: 'Settings',
                onPress: () async {
                  await showSettings(item.data.owner, context: context);
                },
              ),
            if (item.data.isRoot)
              Padding(
                padding: const EdgeInsets.only(right: 7),
                child: FolderTreeItemButton(
                  itemData: item.data,
                  isSelected: isSelected(selectedStream),
                  icon: PackedIcon.add,
                  tooltip: 'New File',
                  onPress: () async {
                    final createdFile =
                        await FileManager().createFile(item.data.owner);

                    // Update current directory.
                    final currentDirectory = Plumber().peek<CurrentDirectory>();
                    if (currentDirectory != null &&
                        currentDirectory.owner == item.data.owner &&
                        currentDirectory.folder.id == 1) {
                      Plumber().message(currentDirectory);
                    }

                    await RiveContext.of(context).open(createdFile);
                  },
                ),
              )
          ]),
        ),
      ),
    );
  }
}

class FolderTreeIcon extends StatelessWidget {
  const FolderTreeIcon({
    this.item,
    this.iconColor,
    Key key,
  }) : super(key: key);

  final Color iconColor;
  final FolderTreeItem item;

  @override
  Widget build(BuildContext context) {
    var colors = RiveTheme.of(context).colors;

    if (item.folder.isRoot) {
      return AvatarView(
        diameter: 15,
        borderWidth: 0,
        imageUrl: item.owner.avatarUrl,
        name: item.owner.displayName,
        color: StageCursor.colorFromPalette(item.owner.ownerId),
      );
    } else {
      return Center(
        child: SizedBox(
          width: 15,
          height: 15,
          child: TintedIcon(
            icon: item.folder.isTrash ? PackedIcon.trash : PackedIcon.folder,
            color: (iconColor == null)
                ? colors.fileUnselectedFolderIcon
                : iconColor,
          ),
        ),
      );
    }
  }
}

class CircleTreeExpander extends StatefulWidget {
  const CircleTreeExpander({
    @required this.item,
    @required this.isSelected,
    Key key,
  }) : super(key: key);

  final FlatTreeItem<FolderTreeItem> item;
  final bool isSelected;

  @override
  State<StatefulWidget> createState() => _CircleTreeExpanderState();
}

class _CircleTreeExpanderState extends State<CircleTreeExpander> {
  bool _isHovered = false;

  Color get borderColor {
    final colors = RiveTheme.of(context).colors;
    if (widget.isSelected) {
      return _isHovered ? Colors.white : colors.selectedTreeLines;
    } else {
      return _isHovered
          ? colors.fileUnselectedFolderIcon
          : colors.filesTreeStroke;
    }
  }

  void setHover(bool value) {
    if (value == _isHovered) {
      return;
    }

    setState(() {
      _isHovered = value;
      widget.item.data.hover = value;
    });
  }

  Color get arrowColor {
    final colors = RiveTheme.of(context).colors;
    if (widget.isSelected) {
      return Colors.white;
    } else {
      return _isHovered
          ? colors.fileBackgroundDarkGrey
          : colors.fileUnselectedFolderIcon;
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return MouseRegion(
      onEnter: (_) => setHover(true),
      onExit: (_) => setHover(false),
      child: Container(
        child: Center(
          child: TreeExpander(
            key: item.key,
            iconColor: arrowColor,
            isExpanded: item.isExpanded,
          ),
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: borderColor,
            width: 1.0,
            style: BorderStyle.solid,
          ),
          borderRadius: const BorderRadius.all(
            Radius.circular(7.5),
          ),
        ),
      ),
    );
  }
}

class FolderTreeItemButton extends StatefulWidget {
  const FolderTreeItemButton({
    @required this.itemData,
    @required this.isSelected,
    @required this.onPress,
    @required this.icon,
    @required this.tooltip,
    Key key,
  }) : super(key: key);

  final FolderTreeItem itemData;
  final bool isSelected;
  final VoidCallback onPress;
  final Iterable<PackedIcon> icon;
  final String tooltip;

  @override
  _FolderTreeItemButtonState createState() => _FolderTreeItemButtonState();
}

class _FolderTreeItemButtonState extends State<FolderTreeItemButton> {
  bool _isHovered = false;

  Color get _rowButtonColor {
    final isSelected = widget.isSelected;
    final colors = RiveTheme.of(context).colors;

    if (isSelected) {
      return _isHovered
          ? colors.treeIconSelectedHovered
          : colors.treeIconSelectedIdle;
    }

    return _isHovered ? colors.treeIconHovered : colors.treeIconIdle;
  }

  void _setHover(bool value) {
    if (_isHovered == value) {
      return;
    }

    setState(() {
      _isHovered = value;
      widget.itemData.hover = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TintedIconButton(
      onPress: widget.onPress,
      icon: widget.icon,
      color: _rowButtonColor,
      backgroundHover: Colors.transparent,
      tip: Tip(
        label: widget.tooltip,
        // Move closer to the row.
        offset: const Offset(0, -7),
      ),
      onHover: _setHover,
    );
  }
}
