import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:rive_api/models/team.dart';

import 'package:rive_core/selectable_item.dart';

import 'package:rive_editor/rive/file_browser/browser_tree_controller.dart';
import 'package:rive_editor/rive/file_browser/file_browser.dart';
import 'package:rive_editor/rive/file_browser/rive_folder.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
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
    var colors = RiveTheme.of(context).colors;
    return TreeView<RiveFolder>(
      style: style,
      controller: controller,
      expanderBuilder: (context, item, style) => Consumer<FileBrowser>(
        builder: (context, browser, child) => Container(
          child: Center(
            child: TreeExpander(
              key: item.key,
              iconColor: browser.selectedFolder == item.data
                  ? Colors.white
                  : colors.fileUnselectedFolderIcon,
              isExpanded: item.isExpanded,
            ),
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: browser.selectedFolder == item.data
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
      ),
      iconBuilder: (context, item, style) => Consumer<FileBrowser>(
        builder: (context, browser, child) => Container(
          width: 15,
          height: 15,
          child: Center(
            child: TintedIcon(
              // TODO: tree should not need to know about teams users
              // this should be done some other way.
              // maybe folder tree's have a 'special' header node
              // maybe we just have a different sliver at the screen layer
              // for it
              icon: (item.data.owner == null)
                  ? 'folder'
                  : (item.data.owner is RiveTeam) ? 'teams' : 'user',
              color: browser.selectedFolder == item.data
                  ? colors.fileSelectedFolderIcon
                  : colors.fileUnselectedFolderIcon,
            ),
          ),
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
      itemBuilder: (context, item, style) => Consumer<FileBrowser>(
        builder: (context, browser, child) => Expanded(
          child: Container(
            child: IgnorePointer(
              child: Text(
                (item.data.owner == null)
                    ? item.data.name
                    : item.data.owner.name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  // fontWeight: FontWeight.w100,
                  color: browser.selectedFolder == item.data
                      ? Colors.white
                      : colors.fileTextLightGrey,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
