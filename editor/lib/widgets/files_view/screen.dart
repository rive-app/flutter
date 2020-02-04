import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:rive_editor/main.dart';
import 'package:rive_editor/rive/file_browser/browser_tree_controller.dart';
import 'package:rive_editor/rive/file_browser/file_browser.dart';
import 'package:rive_editor/rive/file_browser/rive_file.dart';
import 'package:rive_editor/rive/file_browser/rive_folder.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:rive_editor/widgets/common/icon_tile.dart';
import 'package:rive_editor/widgets/marquee_selection.dart';
import 'package:rive_editor/widgets/resize_panel.dart';
import 'package:rive_editor/widgets/theme.dart';

import 'file.dart';
import 'folder_tree.dart';
import 'folder_view_widget.dart';
import 'item_view.dart';
import 'profile_view.dart';

const kFileAspectRatio = kGridWidth / kFileHeight;
const kFileHeight = 190;
const kFolderAspectRatio = kGridWidth / kFolderHeight;
const kFolderHeight = 60;
const kGridHeaderHeight = 50.0;
const kGridSpacing = 30.0;
const kGridWidth = 187.0;

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

class FilesView extends StatelessWidget {
  const FilesView({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const kProfileWidth = 215.0;
    final _rive = Provider.of<Rive>(context, listen: false);
    return ChangeNotifierProvider.value(
      value: _rive.fileBrowser,
      child: GestureDetector(
        onTap: _rive.fileBrowser.deselectAll,
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
                    child: _buildLeftSide(),
                  ),
                  Expanded(
                    child: _buildCenter(_rive),
                  ),
                ],
              ),
            ),
            Container(
              width: kProfileWidth,
              color: ThemeUtils.backgroundLightGrey,
              child: _buildRightSide(_rive),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenter(Rive _rive) {
    final _scrollController = ScrollController();
    return LayoutBuilder(
      builder: (context, dimens) {
        _rive.fileBrowser.sizeChanged(dimens);

        return Consumer<FileBrowser>(
          builder: (context, browser, child) {
            final folders =
                browser.selectedFolder?.children?.cast<RiveFolder>() ?? [];

            if (browser.selectedFolder == null) {
              return _buildEmpty(context);
            }
            var files = browser.selectedFolder.files;

            return ValueListenableBuilder<List<RiveFile>>(
              valueListenable: files,
              builder: (context, files, _) => files.isEmpty
                  ? _buildEmpty(context)
                  : ValueListenableBuilder<bool>(
                      valueListenable: browser.draggingState,
                      builder: (context, dragging, child) => MarqueeScrollView(
                        rive: _rive,
                        enable: !dragging,
                        child: child,
                        controller: _scrollController,
                      ),
                      child: Scrollbar(
                        controller: _scrollController,
                        child: CustomScrollView(
                          controller: _scrollController,
                          physics: NeverScrollableScrollPhysics(),
                          slivers: <Widget>[
                            if (folders != null && folders.isNotEmpty) ...[
                              SliverToBoxAdapter(
                                child: TitleSection(
                                  name: 'Folders',
                                  height: kGridHeaderHeight,
                                  showDropdown: true,
                                ),
                              ),
                              _buildFolders(folders, browser),
                            ],
                            if (files != null && files.isNotEmpty) ...[
                              SliverToBoxAdapter(
                                child: TitleSection(
                                  name: 'Files',
                                  height: kGridHeaderHeight,
                                  showDropdown:
                                      folders == null || folders.isEmpty,
                                ),
                              ),
                              _buildFiles(files, browser, _rive),
                            ],
                          ],
                        ),
                      ),
                    ),
            );
          },
        );
      },
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

  Widget _buildDivider(double left) {
    return Row(children: <Widget>[
      Expanded(child: Container(color: ThemeUtils.lineGrey, height: 1))
    ]);
  }

  Widget _buildEmpty(BuildContext context) {
    return Column(
      children: [
        const TitleSection(
          name: 'Files',
          showDropdown: true,
          height: kGridHeaderHeight,
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

  Widget _buildFeedback(RiveFile file, FileBrowser _fileBrowser) {
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
                file.name ?? "",
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

  Widget _buildFiles(List<RiveFile> files, FileBrowser browser, Rive _rive) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: kGridSpacing),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          // maxCrossAxisExtent: kGridWidth,
          crossAxisCount: browser.crossAxisCount,
          childAspectRatio: kFileAspectRatio,
          mainAxisSpacing: kGridSpacing,
          crossAxisSpacing: kGridSpacing,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final _file = files[index];
            return Container(
              key: _file.key,
              child: ValueListenableBuilder<bool>(
                valueListenable: _file.draggingState,
                builder: (context, fileDragging, child) {
                  return Draggable<RiveFile>(
                    dragAnchor: DragAnchor.pointer,
                    onDragStarted: () {
                      if (!_file.isSelected) {
                        browser.selectItem(_rive, _file);
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
                    feedback: _buildFeedback(_file, browser),
                    childWhenDragging: _buildChildWhenDragging(),
                    child: fileDragging
                        ? _buildChildWhenDragging()
                        : FileViewWidget(
                            // key: _file.key,
                            file: _file,
                          ),
                  );
                },
              ),
            );
          },
          childCount: files.length,
          addRepaintBoundaries: false,
          addAutomaticKeepAlives: false,
          addSemanticIndexes: false,
          // findChildIndexCallback: (Key key) {
          //   return files.indexWhere(
          //       (i) => i.key == key);
          // },
        ),
      ),
    );
  }

  Widget _buildFolders(List<RiveFolder> folders, FileBrowser browser) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: kGridSpacing),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          // maxCrossAxisExtent: kGridWidth,
          crossAxisCount: browser.crossAxisCount,
          childAspectRatio: kFolderAspectRatio,
          mainAxisSpacing: kGridSpacing,
          crossAxisSpacing: kGridSpacing,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final _folder = folders[index];
            return ValueListenableBuilder<Rect>(
              valueListenable: browser.marqueeSelection,
              builder: (context, rect, child) => DragTarget<RiveFile>(
                key: _folder.key,
                builder: (context, accepts, rejects) {
                  return FolderViewWidget(
                    folder: _folder,
                  );
                },
              ),
            );
          },
          childCount: folders.length,
          addRepaintBoundaries: false,
          addAutomaticKeepAlives: false,
          addSemanticIndexes: false,
          // findChildIndexCallback: (Key key) {
          //   return folders.indexWhere(
          //       (i) => i.key == key);
          // },
        ),
      ),
    );
  }

  Widget _buildLeftSide() {
    return Container(
      decoration: BoxDecoration(
        color: ThemeUtils.backgroundLightGrey,
        border: Border(
            right: BorderSide(
          color: Color.fromARGB(255, 216, 216, 216),
        )),
      ),
      padding: EdgeInsets.only(top: 20.0),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(
              right: 20.0,
              left: 20.0,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                    height: 35,
                    padding: EdgeInsets.only(left: 10, right: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5.0),
                      color: Color.fromRGBO(227, 227, 227, 1.0),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
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
                              textAlignVertical: TextAlignVertical.center,
                              decoration: InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: 'Search',
                                contentPadding: EdgeInsets.zero,
                                filled: true,
                                hoverColor: Colors.transparent,
                                fillColor: Colors.transparent,
                              ),
                              style: TextStyle(
                                color: Color.fromRGBO(153, 153, 153, 1.0),
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
          Padding(
            padding: const EdgeInsets.only(left: 20.0),
            child: Column(
              children: <Widget>[
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
              ],
            ),
          ),
          Container(
            height: kTreeItemHeight,
            padding: const EdgeInsets.only(top: 21, bottom: 5),
            child: _buildDivider(0),
          ),
          Expanded(
            child: Consumer<Rive>(
              builder: (context, rive, _) =>
                  ValueListenableBuilder<FolderTreeController>(
                valueListenable: rive.fileBrowser.treeController,
                builder: (context, controller, _) => FolderTreeView(
                  padding: const EdgeInsets.only(
                    left: 20.0,
                    right: 10.0,
                    bottom: 5,
                    top: 5,
                  ),
                  scrollController: rive.fileBrowser.treeScrollController,
                  controller: controller,
                  itemHeight: kTreeItemHeight,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRightSide(Rive _rive) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
            left: BorderSide(
          color: Color.fromARGB(255, 216, 216, 216),
        )),
      ),
      padding: const EdgeInsets.all(20.0),
      child: ValueListenableBuilder<SelectableItem>(
          valueListenable: _rive.fileBrowser.selectedItem,
          builder: (context, selection, child) {
            if (selection != null) {
              return ItemView(item: selection);
            }
            return ProfileView();
          }),
    );
  }
}

class TitleSection extends StatelessWidget {
  final String name;

  final bool showDropdown;
  final double height;
  const TitleSection({
    Key key,
    @required this.name,
    @required this.height,
    this.showDropdown = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: EdgeInsets.only(left: 30.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Container(
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
