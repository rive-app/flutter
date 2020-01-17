import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:rive_editor/main.dart';
import 'package:rive_editor/rive/file_browser/browser_tree_controller.dart';
import 'package:rive_editor/rive/file_browser/file.dart';
import 'package:rive_editor/rive/file_browser/file_browser.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:rive_editor/widgets/common/icon_tile.dart';
import 'package:rive_editor/widgets/marquee_selection.dart';
import 'package:rive_editor/widgets/resize_panel.dart';
import 'package:rive_editor/widgets/theme.dart';
import 'package:provider/provider.dart';

import 'file.dart';
import 'folder.dart';
import 'folder_tree.dart';
import 'item_view.dart';
import 'profile_view.dart';

class FilesView extends StatelessWidget {
  const FilesView({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final padding = const EdgeInsets.symmetric(
      horizontal: 30.0,
      vertical: 10.0,
    );
    const kProfileWidth = 215.0;
    final _rive = Provider.of<Rive>(context, listen: false);
    return ChangeNotifierProvider.value(
      value: _rive.fileBrowser,
      child: GestureDetector(
        onTap: () => _rive.fileBrowser.deselectAll(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ResizePanel(
                    hitSize: resizeEdgeSize,
                    direction: ResizeDirection.horizontal,
                    side: ResizeSide.end,
                    min: 252.0,
                    max: 500,
                    child: Container(
                      color: ThemeUtils.backgroundLightGrey,
                      padding: EdgeInsets.only(left: 20.0, top: 20.0),
                      child: Column(
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(right: 20.0),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Container(
                                    height: 35,
                                    padding:
                                        EdgeInsets.only(left: 10, right: 10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5.0),
                                      color: Color.fromRGBO(227, 227, 227, 1.0),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: <Widget>[
                                        RiveIcons.search(
                                          Color.fromRGBO(153, 153, 153, 1.0),
                                          16.0,
                                        ),
                                        Container(width: 10),
                                        Expanded(
                                          child: Container(
                                            height: 35,
                                            alignment: Alignment.centerLeft,
                                            child: TextField(
                                              textAlign: TextAlign.left,
                                              textAlignVertical:
                                                  TextAlignVertical.center,
                                              decoration: InputDecoration(
                                                isDense: true,
                                                border: InputBorder.none,
                                                hintText: 'Search',
                                                contentPadding: EdgeInsets.zero,
                                                filled: true,
                                                fillColor: Colors.transparent,
                                              ),
                                              style: TextStyle(
                                                color: Color.fromRGBO(
                                                    153, 153, 153, 1.0),
                                                fontSize: 13.0,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Container(width: 10.0),
                                Container(
                                  width: 29,
                                  height: 29,
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: RiveIcons.add(Colors.white, 16),
                                )
                              ],
                            ),
                          ),
                          IconTile(
                            label: "Recents",
                            icon: RiveIcons.clock(ThemeUtils.iconColor, 15),
                            onTap: () {},
                          ),
                          IconTile(
                            icon: RiveIcons.trash(ThemeUtils.iconColor, 15),
                            label: "Deleted Files",
                            onTap: () {},
                          ),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Container(
                                    margin: EdgeInsets.only(
                                      top: 21,
                                      bottom: 11,
                                    ),
                                    color: ThemeUtils.lineGrey,
                                    height: 1),
                              )
                            ],
                          ),
                          Expanded(
                            child: Consumer<Rive>(
                              builder: (context, rive, _) =>
                                  ValueListenableBuilder<FolderTreeController>(
                                valueListenable:
                                    rive.fileBrowser.browserController,
                                builder: (context, controller, _) {
                                  return FolderTreeView(
                                    controller: controller,
                                    scrollController:
                                        rive.fileBrowser.treeScrollController,
                                    itemHeight: kTreeItemHeight,
                                  );
                                },
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Consumer<FileBrowser>(
                      builder: (context, browser, child) => LayoutBuilder(
                        builder: (_, dimens) {
                          final folders =
                              browser?.selectedFolder?.folders ?? [];
                          final files = browser?.selectedFolder?.files ?? [];
                          if (folders.isEmpty && files.isEmpty) {
                            return Column(
                              children: <Widget>[
                                TitleSection(
                                  padding: padding,
                                  name: 'Files',
                                  showDropdown: true,
                                ),
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      "This View is empty.",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }
                          return ValueListenableBuilder<bool>(
                            valueListenable: browser.draggingState,
                            builder: (context, dragging, child) =>
                                MarqueeScrollView(
                              controller: browser.filesScrollController,
                              enable: !dragging,
                              child: child,
                            ),
                            child: Scrollbar(
                              controller: browser.filesScrollController,
                              child: CustomScrollView(
                                // semanticChildCount: 4,
                                controller: browser.filesScrollController,
                                physics: NeverScrollableScrollPhysics(),
                                slivers: <Widget>[
                                  if (folders != null &&
                                      folders.isNotEmpty) ...[
                                    SliverToBoxAdapter(
                                      child: TitleSection(
                                        padding: padding,
                                        name: 'Folders',
                                        showDropdown: true,
                                      ),
                                    ),
                                    SliverPadding(
                                      padding: EdgeInsets.all(20.0),
                                      sliver: SliverGrid(
                                        gridDelegate:
                                            SliverGridDelegateWithMaxCrossAxisExtent(
                                          maxCrossAxisExtent: 187,
                                          childAspectRatio: 187 / 60,
                                          mainAxisSpacing: 20.0,
                                          crossAxisSpacing: 20.0,
                                        ),
                                        delegate: SliverChildBuilderDelegate(
                                          (context, index) {
                                            return DragTarget<FileItem>(
                                              key: folders[index].key,
                                              builder:
                                                  (context, accepts, rejects) {
                                                return FolderViewWidget(
                                                  folder: folders[index],
                                                );
                                              },
                                            );
                                          },
                                          childCount: folders.length,
                                          // findChildIndexCallback: (Key key) {
                                          //   return folders.indexWhere(
                                          //       (i) => i.key == key);
                                          // },
                                          addRepaintBoundaries: false,
                                          addAutomaticKeepAlives: false,
                                          addSemanticIndexes: false,
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (files != null && files.isNotEmpty) ...[
                                    SliverToBoxAdapter(
                                      child: TitleSection(
                                        padding: padding,
                                        name: 'Files',
                                        showDropdown:
                                            folders == null || folders.isEmpty,
                                      ),
                                    ),
                                    SliverPadding(
                                      padding: EdgeInsets.all(20.0),
                                      sliver: SliverGrid(
                                        gridDelegate:
                                            SliverGridDelegateWithMaxCrossAxisExtent(
                                          maxCrossAxisExtent: 187,
                                          childAspectRatio: 187 / 190,
                                          mainAxisSpacing: 20.0,
                                          crossAxisSpacing: 20.0,
                                        ),
                                        delegate: SliverChildBuilderDelegate(
                                          (context, index) {
                                            final file = files[index];
                                            return ValueListenableBuilder<bool>(
                                              valueListenable:
                                                  file.draggingState,
                                              builder: (context, fileDragging,
                                                  child) {
                                                return Draggable<FileItem>(
                                                  dragAnchor:
                                                      DragAnchor.pointer,
                                                  onDragStarted: () {
                                                    if (!file.isSelected) {
                                                      browser.selectItem(
                                                          _rive, file);
                                                    }
                                                    browser.startDrag();
                                                  },
                                                  onDragCompleted: () {
                                                    browser.endDrag();
                                                  },
                                                  onDragEnd: (_) {
                                                    browser.endDrag();
                                                  },
                                                  onDraggableCanceled: (_, __) {
                                                    browser.endDrag();
                                                  },
                                                  feedback: _buildFeedback(
                                                      file, browser),
                                                  childWhenDragging:
                                                      _buildChildWhenDragging(),
                                                  child: fileDragging
                                                      ? _buildChildWhenDragging()
                                                      : FileViewWidget(
                                                          file: files[index]),
                                                );
                                              },
                                            );
                                          },
                                          childCount: files.length,
                                          // findChildIndexCallback: (Key key) {
                                          //   return files.indexWhere(
                                          //       (i) => i.key == key);
                                          // },
                                          addRepaintBoundaries: false,
                                          addAutomaticKeepAlives: false,
                                          addSemanticIndexes: false,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: kProfileWidth,
              color: ThemeUtils.backgroundLightGrey,
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: ValueListenableBuilder<SelectableItem>(
                    valueListenable: _rive.fileBrowser.selection,
                    builder: (context, selection, child) {
                      if (selection != null) {
                        return ItemView(item: selection);
                      }
                      return ProfileView();
                    }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildWhenDragging() {
    return Container(
      width: 187,
      height: 190,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: DottedBorder(
        borderType: BorderType.RRect,
        radius: Radius.circular(12),
        padding: EdgeInsets.all(6),
        color: ThemeUtils.iconColor,
        child: Container(),
        dashPattern: [4, 3],
      ),
    );
  }

  Widget _buildFeedback(FileItem file, FileBrowser _fileBrowser) {
    return SizedBox(
      width: 187,
      height: 50,
      child: Stack(
        fit: StackFit.expand,
        overflow: Overflow.visible,
        children: <Widget>[
          Material(
            elevation: 30.0,
            shadowColor: Colors.grey[50],
            color: ThemeUtils.backgroundLightGrey,
            borderRadius: BorderRadius.circular(10.0),
            child: Container(
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.only(left: 20.0),
              child: Text(
                file.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: ThemeUtils.textGrey),
              ),
            ),
          ),
          if (_fileBrowser.selectedCount > 1)
            Positioned(
              right: -5,
              top: -5,
              width: 20,
              height: 20,
              child: Container(
                child: CircleAvatar(
                  backgroundColor: Colors.red,
                  child: Text(
                    _fileBrowser.selectedCount.toString(),
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class DropDownSortButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final dropDownStyle = const TextStyle(
      color: ThemeUtils.textGrey,
      fontSize: 14.0,
    );
    return DropdownButton<int>(
      value: 0,
      isDense: true,
      underline: Container(),
      icon: Icon(
        Icons.keyboard_arrow_down,
        color: ThemeUtils.iconColor,
      ),
      itemHeight: 50.0,
      items: [
        DropdownMenuItem(
          value: 0,
          child: Text('Recent', style: dropDownStyle),
        ),
        DropdownMenuItem(
          value: 1,
          child: Text('Oldest', style: dropDownStyle),
        ),
        DropdownMenuItem(
          value: 2,
          child: Text('A - Z', style: dropDownStyle),
        ),
        DropdownMenuItem(
          value: 3,
          child: Text('Z - A', style: dropDownStyle),
        ),
      ],
      onChanged: (val) {},
    );
  }
}

class TitleSection extends StatelessWidget {
  const TitleSection({
    Key key,
    @required this.padding,
    @required this.name,
    this.showDropdown = false,
  }) : super(key: key);

  final EdgeInsets padding;
  final String name;
  final bool showDropdown;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Container(
            padding: padding,
            child: Text(
              name,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
          if (showDropdown)
            Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: DropDownSortButton(),
            ),
        ],
      ),
    );
  }
}
