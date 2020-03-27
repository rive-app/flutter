import 'package:cursor/propagating_listener.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:rive_api/files.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:rive_editor/main.dart';
import 'package:rive_editor/rive/file_browser/browser_tree_controller.dart';
import 'package:rive_editor/rive/file_browser/file_browser.dart';
import 'package:rive_editor/rive/file_browser/rive_file.dart';
import 'package:rive_editor/rive/file_browser/rive_folder.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:rive_editor/widgets/common/combo_box.dart';
import 'package:rive_editor/widgets/common/dashed_flat_button.dart';
import 'package:rive_editor/widgets/common/icon_tile.dart';
import 'package:rive_editor/widgets/common/separator.dart';
import 'package:rive_editor/widgets/dialog/team_wizard/team_wizard.dart';
import 'package:rive_editor/widgets/files_view/file.dart';
import 'package:rive_editor/widgets/files_view/folder_tree.dart';
import 'package:rive_editor/widgets/files_view/folder_view_widget.dart';
import 'package:rive_editor/widgets/files_view/item_view.dart';
import 'package:rive_editor/widgets/files_view/profile_view.dart';
import 'package:rive_editor/widgets/files_view/top_nav.dart';
import 'package:rive_editor/widgets/icons.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/marquee_selection.dart';
import 'package:rive_editor/widgets/popup/popup_direction.dart';
import 'package:rive_editor/widgets/popup/tip.dart';
import 'package:rive_editor/widgets/resize_panel.dart';
import 'package:tree_widget/tree_scroll_view.dart';
import 'package:tree_widget/tree_style.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

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

  Widget _buildCenter(Rive rive) {
    final fileBrowser = rive.fileBrowser;
    final scrollController = ScrollController();

    return LayoutBuilder(
      builder: (context, dimens) {
        fileBrowser.sizeChanged(dimens);

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
                        rive: rive,
                        enable: !dragging,
                        child: child,
                        controller: scrollController,
                      ),
                      child: CustomScrollView(
                        controller: scrollController,
                        physics: const NeverScrollableScrollPhysics(),
                        slivers: <Widget>[
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 15),
                              child: TopNav(fileBrowser),
                            ),
                          ),
                          if (folders != null && folders.isNotEmpty) ...[
                            const SliverToBoxAdapter(
                              child: TitleSection(
                                name: 'Folders',
                                height: kGridHeaderHeight,
                                showDropdown: false,
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
                            _buildFiles(context, files, browser, rive),
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

  Widget _buildDivider(Color color, {double left = 0}) {
    return Row(children: <Widget>[
      Expanded(
        child: Separator(
          color: color,
          padding: EdgeInsets.only(left: left),
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
    if (files == null || files.isEmpty) return null;

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
    if (folders == null || folders.isEmpty) return null;

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
    final theme = RiveTheme.of(context);
    final riveColors = theme.colors;
    final treeStyle = TreeStyle(
      showFirstLine: false,
      padding: const EdgeInsets.only(
        left: 20.0,
        right: 10.0,
        bottom: 5,
        top: 5,
      ),
      lineColor: RiveTheme.of(context).colors.fileLineGrey,
      itemHeight: kTreeItemHeight,
    );

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
                        style: RiveTheme.of(context).textStyles.fileSearchText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20.0),
            child: Column(
              children: <Widget>[
                IconTile(
                  label: 'Get Started',
                  icon: TintedIcon(
                    color: RiveTheme.of(context).colors.fileIconColor,
                    icon: 'rocket',
                  ),
                  onTap: () {},
                ),
                IconTile(
                  icon: TintedIcon(
                    color: RiveTheme.of(context).colors.fileIconColor,
                    icon: 'notification',
                  ),
                  label: 'Notifications',
                  onTap: () {},
                ),
                IconTile(
                  icon: TintedIcon(
                    color: RiveTheme.of(context).colors.fileIconColor,
                    icon: 'recents',
                  ),
                  label: 'Recents',
                  onTap: () {},
                ),
                IconTile(
                  icon: TintedIcon(
                    color: RiveTheme.of(context).colors.fileIconColor,
                    icon: 'popup-community',
                  ),
                  label: 'Community',
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
                  RiveContext.of(context).fileBrowser.myTreeController,
              builder: (context, myTreeController, _) =>
                  ValueListenableBuilder<List<FolderTreeController>>(
                valueListenable:
                    RiveContext.of(context).fileBrowser.teamsTreeControllers,
                builder: (context, teamControllers, _) {
                  var separatorPadding = EdgeInsets.only(
                    left: treeStyle.padding.left,
                    top: 12,
                    bottom: 12,
                  );
                  var slivers = <Widget>[
                    FolderTreeView(
                      style: treeStyle,
                      controller: myTreeController,
                    ),
                    SliverToBoxAdapter(
                      child: Separator(
                        color: riveColors.fileLineGrey,
                        padding: separatorPadding,
                      ),
                    ),
                  ];
                  for (int i = 0; i < teamControllers.length; i++) {
                    slivers.add(
                      FolderTreeView(
                        style: treeStyle,
                        controller: teamControllers[i],
                      ),
                    );
                    slivers.add(
                      SliverToBoxAdapter(
                        child: Separator(
                          color: riveColors.fileLineGrey,
                          padding: separatorPadding,
                        ),
                      ),
                    );
                  }

                  slivers.add(
                    SliverPadding(
                      padding: EdgeInsets.only(
                        left: treeStyle.padding.left,
                        right: treeStyle.padding.right,
                        top: 8,
                        bottom: 20,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: DashedFlatButton(
                          label: 'New Team',
                          icon: 'teams-button',
                          tip: const Tip(
                              label: 'Create a new team',
                              direction: PopupDirection.topToCenter),
                          onTap: () => showTeamWizard<void>(
                            context: context,
                          ),
                        ),
                      ),
                    ),
                  );

                  return TreeScrollView(
                    scrollController: RiveContext.of(context)
                        .fileBrowser
                        .treeScrollController,
                    style: treeStyle,
                    slivers: slivers,
                  );
                },
              ),
            ),
          ),
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
    @required this.name,
    @required this.height,
    Key key,
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
