import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';

import 'package:cursor/propagating_listener.dart';

import 'package:rive_api/files.dart';
import 'package:rive_api/models/team.dart';

import 'package:rive_core/selectable_item.dart';
import 'package:rive_editor/widgets/home/team_detail_panel.dart';
import 'package:rive_editor/widgets/notifications.dart';

import 'package:tree_widget/tree_scroll_view.dart';
import 'package:tree_widget/tree_style.dart';

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
import 'package:rive_editor/widgets/home/file.dart';
import 'package:rive_editor/widgets/home/folder_tree.dart';
import 'package:rive_editor/widgets/home/folder_view_widget.dart';
import 'package:rive_editor/widgets/home/item_view.dart';
import 'package:rive_editor/widgets/home/profile_view.dart';
import 'package:rive_editor/widgets/home/sliver_inline_footer.dart';
import 'package:rive_editor/widgets/home/top_nav.dart';
import 'package:rive_editor/widgets/icons.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/popup/popup_direction.dart';
import 'package:rive_editor/widgets/popup/tip.dart';
import 'package:rive_editor/widgets/resize_panel.dart';
import 'package:provider/provider.dart';

const double kFileAspectRatio = kGridWidth / kFileHeight;
const double kFileHeight = 190;
const double kFolderAspectRatio = kGridWidth / kFolderHeight;
const double kFolderHeight = 60;
const double kGridHeaderHeight = 50;
const double kGridSpacing = 30;
const double kGridWidth = 187;

/// The home screen, where a user can find their files,
/// notifications, community, etc.
class Home extends StatelessWidget {
  const Home({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final rive = RiveContext.of(context);
    final fileBrowser = rive.activeFileBrowser.value;

    return PropagatingListener(
      behavior: HitTestBehavior.deferToChild,
      onPointerUp: (_) => fileBrowser?.deselectAll(),
      child: ValueListenableBuilder<FileBrowser>(
        valueListenable: rive.activeFileBrowser,
        builder: (context, browser, _) => ChangeNotifierProvider.value(
          value: browser,
          child: Consumer<FileBrowser>(
            builder: (context, fileBrowser, child) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ResizePanel(
                  hitSize: resizeEdgeSize,
                  direction: ResizeDirection.horizontal,
                  side: ResizeSide.end,
                  min: 252,
                  max: 500,
                  child: NavigationPanel(),
                ),
                Expanded(
                  child: MainPanel(),
                ),
                if (fileBrowser.owner is RiveTeam)
                  ResizePanel(
                    hitSize: resizeEdgeSize,
                    direction: ResizeDirection.horizontal,
                    side: ResizeSide.start,
                    min: 252,
                    max: 500,
                    child: TeamDetailPanel(team: fileBrowser.owner as RiveTeam),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Displays the appropriate content/widgets in the main
/// display of the Home panel
class MainPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sectionListener = RiveContext.of(context).sectionListener;
    return ValueListenableBuilder<HomeSection>(
        valueListenable: sectionListener,
        builder: (context, section, _) {
          switch (section) {
            case HomeSection.notifications:
              return NotificationsPanel();
            case HomeSection.community:
            case HomeSection.getStarted:
            case HomeSection.recents:
            case HomeSection.files:
            default:
              return FilesPanel();
          }
        });
  }
}

/// Displays user or team files and folders
class FilesPanel extends StatelessWidget {
  /// Displayed when a files view is selected, but has no files
  Widget _buildEmpty(BuildContext context) {
    return const Center(
      child: Text(
        'Hey, it looks like you don\'t have any files here '
        'yet!\nHit the plus button to create a new file!',
        style: TextStyle(color: Colors.grey),
        textAlign: TextAlign.center,
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

  @override
  Widget build(BuildContext context) {
    final rive = RiveContext.of(context);
    final fileBrowser = rive.activeFileBrowser.value;

    if (fileBrowser?.selectedFolder == null) {
      return _buildEmpty(context);
    }
    return LayoutBuilder(
      builder: (context, dimens) {
        fileBrowser.sizeChanged(dimens);
        final folders =
            fileBrowser.selectedFolder?.children?.cast<RiveFolder>() ?? [];

        if (fileBrowser.selectedFolder == null) {
          return _buildEmpty(context);
        }
        var files = fileBrowser.selectedFolder.files;
        return ValueListenableBuilder<List<RiveFile>>(
          valueListenable: files,
          builder: (context, files, _) => ValueListenableBuilder<bool>(
            valueListenable: fileBrowser.draggingState,
            builder: (context, dragging, child) => CustomScrollView(
              controller: ScrollController(),
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
                  _buildFolders(folders, fileBrowser),
                ],
                if (files != null && files.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: TitleSection(
                      name: 'Files',
                      height: kGridHeaderHeight,
                      showDropdown: folders == null || folders.isEmpty,
                    ),
                  ),
                  _buildFiles(context, files, fileBrowser, rive),
                ],
                if (files != null && files.isEmpty && folders.isEmpty) ...[
                  SliverFillRemaining(child: _buildEmpty(context))
                ]
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The options panel, typically on the left side of
/// the home screen
class NavigationPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    final rive = RiveContext.of(context);
    final riveColors = theme.colors;
    final treeStyle = TreeStyle(
      showFirstLine: false,
      padding: const EdgeInsets.only(
        left: 10,
        right: 10,
        bottom: 0,
        top: 5,
      ),
      lineColor: RiveTheme.of(context).colors.lightTreeLines,
      itemHeight: kTreeItemHeight,
    );

    // this listener is in place to force everything to redraw once the
    // activeFileBrowser chagnes.
    // without this, if you change between teams, only one half of the
    // state changes... (the color of the text, the
    // background comes from within the browser..)
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
          ValueListenableBuilder<HomeSection>(
            valueListenable: rive.sectionListener,
            builder: (context, section, _) => Padding(
              padding: const EdgeInsets.only(top: 10, left: 20),
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: IconTile(
                      label: 'Get Started',
                      iconName: 'rocket',
                      onTap: () {},
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: IconTile(
                      iconName: 'notification',
                      label: 'Notifications',
                      highlight: section == HomeSection.notifications,
                      onTap: () {
                        // File browsers track their own selected states.
                        // so you have to tell them specifically that stuff not selected
                        rive.activeFileBrowser.value?.openFolder(null, false);
                        rive.activeFileBrowser.value = null;
                        rive.sectionListener.value = HomeSection.notifications;
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: IconTile(
                      iconName: 'recents',
                      label: 'Recents',
                      onTap: () {},
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: IconTile(
                      iconName: 'popup-community',
                      label: 'Community',
                      onTap: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
          Separator(
            color: riveColors.fileLineGrey,
            padding: const EdgeInsets.only(
              top: 20,
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<List<FolderTreeController>>(
              valueListenable: RiveContext.of(context).folderTreeControllers,
              builder: (context, folderTreeControllers, _) {
                var slivers = <Widget>[];
                if (folderTreeControllers != null) {
                  for (int i = 0; i < folderTreeControllers.length; i++) {
                    slivers.add(
                      FolderTreeView(
                        style: treeStyle,
                        controller: folderTreeControllers[i],
                      ),
                    );
                    if (i != folderTreeControllers.length - 1) {
                      slivers.add(
                        SliverToBoxAdapter(
                          child: Separator(
                            color: riveColors.fileLineGrey,
                            padding: EdgeInsets.only(
                              left: treeStyle.padding.left,
                              right: 0,
                              top: 12,
                              bottom: 12,
                            ),
                          ),
                        ),
                      );
                    }
                  }
                }

                slivers.add(
                  SliverInlineFooter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Separator(
                          color: riveColors.fileLineGrey,
                          padding: EdgeInsets.only(
                            left: treeStyle.padding.left,
                            top: 12,
                            bottom: 0,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 20,
                            right: 10,
                            bottom: 20,
                            top: 20,
                          ),
                          child: DashedFlatButton(
                            label: 'New Team',
                            icon: 'teams-button',
                            tip: const Tip(
                              label: 'Create a new team',
                              direction: PopupDirection.bottomToCenter,
                              fallbackDirections: [
                                PopupDirection.topToCenter,
                              ],
                            ),
                            onTap: () => showTeamWizard<void>(
                              context: context,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
                return TreeScrollView(
                  scrollController:
                      RiveContext.of(context).treeScrollController,
                  style: treeStyle,
                  slivers: slivers,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class UserPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final rive = RiveContext.of(context);
    final colors = RiveTheme.of(context).colors;
    return Container(
      width: 215,
      color: colors.fileBackgroundLightGrey,
      decoration: const BoxDecoration(
        border: Border(
            left: BorderSide(
          color: Color.fromARGB(255, 216, 216, 216),
        )),
      ),
      padding: const EdgeInsets.all(20),
      child: ValueListenableBuilder<SelectableItem>(
          valueListenable: rive.activeFileBrowser.value.selectedItem,
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
    final fileBrowser = RiveContext.of(context).activeFileBrowser.value;
    var options = fileBrowser.sortOptions.value;
    var theme = RiveTheme.of(context);
    return Container(
      height: height,
      padding: const EdgeInsets.only(left: 30),
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
              padding: const EdgeInsets.only(right: 20),
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
