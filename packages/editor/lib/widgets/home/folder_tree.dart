import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:rive_api/models/team.dart';

import 'package:rive_core/selectable_item.dart';

import 'package:rive_editor/rive/file_browser/browser_tree_controller.dart';
import 'package:rive_editor/rive/file_browser/file_browser.dart';
import 'package:rive_editor/rive/file_browser/rive_folder.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/theme.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';
import 'package:rive_editor/widgets/tree_view/drop_item_background.dart';
import 'package:rive_editor/widgets/tree_view/tree_expander.dart';

import 'package:tree_widget/flat_tree_item.dart';
import 'package:tree_widget/tree_style.dart';
import 'package:tree_widget/tree_widget.dart';

/// Builds a TreeView styled for folders.
class FolderTreeView extends StatelessWidget {
  final FolderTreeController controller;
  final TreeStyle style;

  const FolderTreeView({
    @required this.controller,
    this.style,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = RiveTheme.of(context).colors;
    final fileBrowser = RiveContext.of(context).activeFileBrowser.value;
    return TreeView<RiveFolder>(
      style: style,
      controller: controller,
      expanderBuilder: (context, item, style) => Container(
        child: Center(
          child: TreeExpander(
            key: item.key,
            iconColor: fileBrowser?.selectedFolder == item.data
                ? Colors.white
                : colors.fileUnselectedFolderIcon,
            isExpanded: item.isExpanded,
          ),
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: fileBrowser?.selectedFolder == item.data
                ? colors.selectedTreeLines
                : style.lineColor,
            width: 1.0,
            style: BorderStyle.solid,
          ),
          borderRadius: const BorderRadius.all(
            Radius.circular(7.5),
          ),
        ),
      ),
      iconBuilder: (context, item, style) => Container(
        width: 15,
        height: 15,
        child: Center(
          child:
              TreeRowIcon(item: item, colors: colors, fileBrowser: fileBrowser),
        ),
      ),
      extraBuilder: (context, item, index) => Container(),
      backgroundBuilder: (context, item, style) =>
          ValueListenableBuilder<SelectionState>(
        valueListenable: item.data.selectionState,
        builder: (context, selectionState, _) => DropItemBackground(
          DropState.none,
          selectionState,
        ),
      ),
      itemBuilder: (context, item, style) => Expanded(
        child: Container(
          child: IgnorePointer(
            child: Text(
              (item.data.owner == null)
                  ? item.data.name
                  : item.data.owner.displayName,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                // fontWeight: FontWeight.w100,
                color: fileBrowser?.selectedFolder == item.data
                    ? Colors.white
                    : colors.fileTextLightGrey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TreeRowIcon extends StatelessWidget {
  // TODO: tree should not need to know about teams users
  // this should be done some other way.
  // maybe folder tree's have a 'special' header node
  // maybe we just have a different sliver at the screen layer
  // for it
  const TreeRowIcon({
    @required this.item,
    @required this.colors,
    @required this.fileBrowser,
    Key key,
  }) : super(key: key);

  final FlatTreeItem<RiveFolder> item;
  final RiveColors colors;
  final FileBrowser fileBrowser;

  @override
  Widget build(BuildContext context) {
    if (item.data.owner?.avatar != null) {
      return Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircleAvatar(
            backgroundColor: Colors.transparent,
            backgroundImage: NetworkImage(item.data.owner?.avatar),
          ),
        ),
      );
    } else {
      return TintedIcon(
        icon: (item.data.owner == null)
            ? 'folder'
            : (item.data.owner is RiveTeam) ? 'teams' : 'user',
        color: fileBrowser?.selectedFolder == item.data
            ? colors.fileSelectedFolderIcon
            : colors.fileUnselectedFolderIcon,
      );
    }
  }
}
