import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rive_api/model.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:rive_editor/rive/file_browser/browser_tree_controller.dart';
import 'package:rive_editor/rive/stage/items/stage_cursor.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
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
              icon: 'folder',
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
