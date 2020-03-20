import 'package:cursor/propagating_listener.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:dotted_border/dotted_border.dart';

import 'package:rive_api/files.dart';

import 'package:rive_core/selectable_item.dart';

import 'package:rive_editor/main.dart';
import 'package:rive_editor/rive/file_browser/browser_tree_controller.dart';
import 'package:rive_editor/rive/file_browser/file_browser.dart';
import 'package:rive_editor/rive/file_browser/rive_file.dart';
import 'package:rive_editor/rive/file_browser/rive_folder.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:rive_editor/widgets/common/combo_box.dart';
import 'package:rive_editor/widgets/common/icon_tile.dart';
import 'package:rive_editor/widgets/common/tinted_icon_button.dart';
import 'package:rive_editor/widgets/dialog/settings_panel.dart';
import 'package:rive_editor/widgets/dialog/team_settings_panel.dart';
import 'package:rive_editor/widgets/icons.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/marquee_selection.dart';
import 'package:rive_editor/widgets/popup/list_popup.dart';
import 'package:rive_editor/widgets/popup/popup.dart';
import 'package:rive_editor/widgets/resize_panel.dart';

import 'package:rive_editor/widgets/files_view/file.dart';
import 'package:rive_editor/widgets/files_view/folder_tree.dart';
import 'package:rive_editor/widgets/files_view/folder_view_widget.dart';
import 'package:rive_editor/widgets/files_view/item_view.dart';
import 'package:rive_editor/widgets/files_view/profile_view.dart';

const double kFileAspectRatio = kGridWidth / kFileHeight;
const double kFileHeight = 190;
const double kFolderAspectRatio = kGridWidth / kFolderHeight;
const double kFolderHeight = 60;
const double kGridHeaderHeight = 50;
const double kGridSpacing = 30;
const double kGridWidth = 187;

class FilesView extends StatelessWidget {
  const FilesView({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const double kProfileWidth = 215;
    final _rive = RiveContext.of(context);
    final riveColors = RiveTheme.of(context).colors;
    return ChangeNotifierProvider.value(
      value: _rive.fileBrowser,
      child: PropagatingListener(
        behavior: HitTestBehavior.deferToChild,
        onPointerUp: (_) {
          _rive.fileBrowser.deselectAll();
        },
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
                    child: _buildLeftSide(context),
                  ),
                  Expanded(
                    child: _buildCenter(_rive),
                  ),
                ],
              ),
            ),
            Container(
              width: kProfileWidth,
              color: riveColors.fileBackgroundLightGrey,
              child: _buildRightSide(_rive),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenter(Rive _rive) {
    final fileBrowser = _rive.fileBrowser;
    return LayoutBuilder(builder: (context, constraints) {
      // _rive.fileBrowser.sizeChanged(constraints);
      final riveColors = RiveTheme.of(context).colors;
      return Padding(
        padding: const EdgeInsets.only(top: 15, left: 30, right: 30),
        child: Column(children: [
          Row(children: [
            PopupButton<PopupContextItem>(
              builder: (context) {
                return Container(
                  width: 29,
                  height: 29,
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(51, 51, 51, 1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const AddIcon(color: Colors.white, size: 20),
                );
              },
              itemBuilder: (context, item, isHovered) =>
                  item.itemBuilder(context, isHovered),
              items: [
                PopupContextItem('New File', select: fileBrowser.createFile),
                PopupContextItem('New Folder', select: () {
                  print('Create Folder!');
                })
              ],
            ),
            Container(
              // Buttons padding.
              width: 10,
            ),
            // Wrap in LayoutBuilder to provide the child context for the 
            // ListPopup to show up.
            LayoutBuilder(builder: (userContext, constraints) {
              return TintedIconButton(
                onPress: () {
                  ListPopup<PopupContextItem>.show(userContext,
                      itemBuilder: (userContext, item, isHovered) =>
                          item.itemBuilder(userContext, isHovered),
                      items: [
                        PopupContextItem('Your Profile', select: () {
                          print('Profile?');
                        })
                      ],
                      width: 177);
                },
                icon: 'user',
                backgroundHover: const Color(0xFFF1F1F1),
                iconHover: const Color(0xFF666666),
                padding:
                    const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              );
            }),
            // Wrap in LayoutBuilder to provide the child context for the 
            // ListPopup to show up.
            LayoutBuilder(builder: (settingsContext, constraints) {
              return TintedIconButton(
                onPress: () {
                  ListPopup<PopupContextItem>.show(settingsContext,
                      itemBuilder: (settingsContext, item, isHovered) =>
                          item.itemBuilder(settingsContext, isHovered),
                      items: [
                        PopupContextItem('Settings', select: () {
                          print('Settings?');
                        })
                      ],
                      width: 177);
                },
                icon: 'settings',
                backgroundHover: const Color(0xFFF1F1F1),
                iconHover: const Color(0xFF666666),
                padding:
                    const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              );
            }),
          ]),
          Padding(
            padding: const EdgeInsets.only(top: 18.0, bottom: 30),
            child: _buildDivider(riveColors.fileLineGrey),
          )
        ]),
      );
    });

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
              builder: (context, files, _) => files.isEmpty && folders.isEmpty
                  ? _buildEmpty(context)
                  : ValueListenableBuilder<bool>(
                      valueListenable: browser.draggingState,
                      builder: (context, dragging, child) => MarqueeScrollView(
                        rive: _rive,
                        enable: !dragging,
                        child: child,
                        controller: _scrollController,
                      ),
                      child: CustomScrollView(
                        controller: _scrollController,
                        physics: const NeverScrollableScrollPhysics(),
                        slivers: <Widget>[
                          if (folders != null && folders.isNotEmpty) ...[
                            const SliverToBoxAdapter(
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
                            _buildFiles(context, files, browser, _rive),
                          ],
                        ],
                      ),
                    ),
            );
          },
        );
      },
    );
  }

  Widget _buildChildWhenDragging(BuildContext context) {
    return Container(
      width: 187,
      height: 190,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: DottedBorder(
        borderType: BorderType.RRect,
        radius: const Radius.circular(12),
        padding: const EdgeInsets.all(6),
        color: RiveTheme.of(context).colors.fileIconColor,
        child: Container(),
        dashPattern: const [4, 3],
      ),
    );
  }

  Widget _buildDivider(Color color) {
    return Row(children: <Widget>[
      Expanded(
        child: Container(
          color: color,
          height: 1,
        ),
      )
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
              'This View is empty.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedback(
      BuildContext context, RiveFile file, FileBrowser _fileBrowser) {
    final selectedCount = _fileBrowser.selectedItems.length;
    return SizedBox(
      width: 187,
      height: 50,
      child: Stack(
        fit: StackFit.expand,
        overflow: Overflow.visible,
        children: <Widget>[
          Material(
            elevation: 30,
            shadowColor: Colors.grey[50],
            color: RiveTheme.of(context).colors.fileBackgroundLightGrey,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20),
              child: Text(
                file.name ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: RiveTheme.of(context).textStyles.greyText,
              ),
            ),
          ),
          if (selectedCount > 1)
            Positioned(
              right: -5,
              top: -5,
              width: 20,
              height: 20,
              child: Container(
                child: CircleAvatar(
                  backgroundColor: Colors.red,
                  child: Text(
                    selectedCount.toString(),
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

  Widget _buildFiles(BuildContext context, List<RiveFile> files,
      FileBrowser browser, Rive _rive) {
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
                  return FileViewWidget(
                    // key: _file.key,
                    file: _file,
                  );
                  /** 
                  Draggable<RiveFile>(
                    dragAnchor: DragAnchor.pointer,
                    onDragStarted: () {
                      print("Start drag!");
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
                    feedback: _buildFeedback(context, _file, browser),
                    childWhenDragging: _buildChildWhenDragging(context),
                    child: fileDragging
                        ? _buildChildWhenDragging(context)
                        : FileViewWidget(
                            // key: _file.key,
                            file: _file,
                          ),
                  );
                    */
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

  Widget _buildLeftSide(BuildContext context) {
    final rive = RiveContext.of(context);
    final theme = RiveTheme.of(context);
    final riveColors = theme.colors;
    return Container(
      decoration: BoxDecoration(
        color: riveColors.fileBackgroundLightGrey,
        border: Border(
            right: BorderSide(
          color: riveColors.fileBorder,
        )),
      ),
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(
              right: 20,
              left: 20,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                    height: 35,
                    padding: const EdgeInsets.only(left: 10, right: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: riveColors.fileSearchBorder,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        SearchIcon(
                          color: riveColors.fileSearchIcon,
                          size: 16,
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
                              style: RiveTheme.of(context)
                                  .textStyles
                                  .fileSearchText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(width: 10.0),
                PopupButton<PopupContextItem>(
                  items: [
                    PopupContextItem(
                      'New File',
                      select: rive.fileBrowser.createFile,
                    ),
                    PopupContextItem('New Folder', select: () {}),
                    PopupContextItem.separator(),
                    PopupContextItem(
                      "New Team",
                      select: () => showRiveSettings<void>(
                        context: context,
                        screens: teamSettingsScreens,
                      ),
                    ),
                  ],
                  builder: (context) {
                    return Container(
                      width: 29,
                      height: 29,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const AddIcon(color: Colors.white, size: 13),
                    );
                  },
                  itemBuilder: (context, item, isHovered) => item.itemBuilder(
                    context,
                    isHovered,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20.0),
            child: Column(
              children: <Widget>[
                IconTile(
                  label: 'Recents',
                  icon: const ClockIcon(size: 15),
                  onTap: () {},
                ),
                IconTile(
                  icon: const TrashIcon(size: 15),
                  label: 'Deleted Files',
                  onTap: () {},
                ),
              ],
            ),
          ),
          Container(
            height: kTreeItemHeight,
            padding: const EdgeInsets.only(top: 21, bottom: 5),
            child: _buildDivider(riveColors.fileLineGrey),
          ),
          Expanded(
            child: ValueListenableBuilder<FolderTreeController>(
              valueListenable:
                  RiveContext.of(context).fileBrowser.treeController,
              builder: (context, controller, _) => FolderTreeView(
                padding: const EdgeInsets.only(
                  left: 20.0,
                  right: 10.0,
                  bottom: 5,
                  top: 5,
                ),
                scrollController:
                    RiveContext.of(context).fileBrowser.treeScrollController,
                controller: controller,
                itemHeight: kTreeItemHeight,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRightSide(Rive _rive) {
    return Container(
      decoration: const BoxDecoration(
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
            return const ProfileView();
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
    final fileBrowser = RiveContext.of(context).fileBrowser;
    var options = fileBrowser.sortOptions.value;
    var theme = RiveTheme.of(context);
    return Container(
      height: height,
      padding: const EdgeInsets.only(left: 30.0),
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
              child: ValueListenableBuilder<RiveFileSortOption>(
                valueListenable: fileBrowser.selectedSortOption,
                builder: (context, sortOption, _) =>
                    ComboBox<RiveFileSortOption>(
                  popupWidth: 100,
                  sizing: ComboSizing.collapsed,
                  underline: false,
                  valueColor: theme.colors.toolbarButton,
                  options: options,
                  value: sortOption,
                  toLabel: (option) => option.name,
                  change: (option) =>
                      fileBrowser.loadFileList(sortOption: option),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
