import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rive_editor/rive/file_browser/browser_tree_controller.dart';
import 'package:rive_editor/rive/file_browser/file_browser.dart';
import 'package:rive_editor/rive/file_browser/folder.dart';
import 'package:rive_editor/widgets/theme.dart';
import 'package:rive_editor/widgets/tree_view/drop_item_background.dart';
import 'package:rive_editor/widgets/tree_view/tree_expander.dart';
import 'package:tree_widget/flat_tree_item.dart';
import 'package:tree_widget/tree_style.dart';
import 'package:tree_widget/tree_widget.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:provider/provider.dart';

class FolderTreeView extends StatelessWidget {
  final FolderTreeController controller;
  final ScrollController scrollController;
  final double itemHeight;

  const FolderTreeView({
    Key key,
    @required this.controller,
    @required this.scrollController,
    @required this.itemHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TreeView<FolderItem>(
      scrollController: scrollController,
      shrinkWrap: false,
      style: TreeStyle(
        showFirstLine: true,
        padding: const EdgeInsets.all(5),
        lineColor: ThemeUtils.lineGrey,
        itemHeight: itemHeight,
      ),
      controller: controller,
      expanderBuilder: (context, item) => Container(
        child: Center(
          child: TreeExpander(
            key: item.key,
            iconColor: Colors.grey,
            isExpanded: item.isExpanded,
          ),
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: ThemeUtils.lineGrey,
            width: 1.0,
            style: BorderStyle.solid,
          ),
          borderRadius: const BorderRadius.all(
            Radius.circular(7.5),
          ),
        ),
      ),
      iconBuilder: (context, item) => Consumer<FileBrowser>(
        builder: (context, browser, child) => Container(
          width: 15,
          height: 15,
          child: Center(
              child: RiveIcons.folder(
            browser.selectedFolder == item.data
                ? Colors.white
                : ThemeUtils.iconColor,
            15.0,
          )),
        ),
      ),
      extraBuilder: (context, item, index) => Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.white,
            width: 1.0,
            style: BorderStyle.solid,
          ),
          borderRadius: const BorderRadius.all(
            Radius.circular(7.5),
          ),
        ),
      ),
      backgroundBuilder: (context, item) => Consumer<FileBrowser>(
        builder: (context, browser, child) => DropItemBackground(
          DropState.none,
          browser.selectedFolder.key == item.data.key
              ? SelectionState.selected
              : SelectionState.none,
          selectedElevation: 4.0,
        ),
      ),
      itemBuilder: (context, item) => Consumer<FileBrowser>(
        builder: (context, browser, child) => Expanded(
          child: IgnorePointer(
            child: Text(
              item.data.name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: browser.selectedFolder.key == item.data.key
                    ? Colors.white
                    : Colors.grey.shade500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
