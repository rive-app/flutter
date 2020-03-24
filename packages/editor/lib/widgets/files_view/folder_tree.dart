import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:rive_core/selectable_item.dart';

import 'package:rive_editor/rive/file_browser/browser_tree_controller.dart';
import 'package:rive_editor/rive/file_browser/file_browser.dart';
import 'package:rive_editor/rive/file_browser/rive_folder.dart';
import 'package:rive_editor/widgets/icons.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/tree_view/drop_item_background.dart';
import 'package:rive_editor/widgets/tree_view/tree_expander.dart';

import 'package:tree_widget/flat_tree_item.dart';
import 'package:tree_widget/tree_style.dart';
import 'package:tree_widget/tree_widget.dart';

class FolderTreeView extends StatelessWidget {
  final FolderTreeController controller;
  final double itemHeight;
  final ScrollController scrollController;
  final EdgeInsets padding;
  final List<Widget> trailingWidgets;

  const FolderTreeView(
      {@required this.controller,
      @required this.itemHeight,
      this.padding = const EdgeInsets.all(5),
      Key key,
      this.scrollController,
      this.trailingWidgets = const []})
      : super(key: key);

  @override
  Widget build(BuildContext context) => TreeView<RiveFolder>(
        scrollController: scrollController,
        shrinkWrap: false,
        trailingWidgets: trailingWidgets,
        style: TreeStyle(
          showFirstLine: false,
          padding: padding,
          lineColor: RiveTheme.of(context).colors.fileLineGrey,
          itemHeight: itemHeight,
        ),
        separatorBuilder: (_, index) => Center(
          child: Container(
            height: 1,
            padding: const EdgeInsets.only(left: 20.0),
            color: const Color.fromRGBO(227, 227, 227, 1),
          ),
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
              color: RiveTheme.of(context).colors.fileLineGrey,
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
              child: FolderIcon(
                color: browser.selectedFolder == item.data
                    ? RiveTheme.of(context).colors.fileSelectedFolderIcon
                    : RiveTheme.of(context).colors.fileUnselectedFolderIcon,
              ),
            ),
          ),
        ),
        extraBuilder: (context, item, index) => Container(),
        backgroundBuilder: (context, item) => Consumer<FileBrowser>(
          builder: (context, browser, child) => DropItemBackground(
            DropState.none,
            browser.selectedFolder.key == item.data.key
                ? SelectionState.selected
                : SelectionState.none,
          ),
        ),
        itemBuilder: (context, item) => Consumer<FileBrowser>(
          builder: (context, browser, child) => Expanded(
            child: Container(
              child: IgnorePointer(
                child: Text(
                  item.data.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    // fontWeight: FontWeight.w100,
                    color: browser.selectedFolder.key == item.data.key
                        ? Colors.white
                        : RiveTheme.of(context).colors.fileTextLightGrey,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
