import 'package:cursor/propagating_listener.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:rive_api/models/team.dart';
import 'package:rive_editor/rive/file_browser/file_browser.dart';
import 'package:rive_editor/rive/file_browser/rive_file.dart';
import 'package:rive_editor/rive/file_browser/rive_folder.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:rive_editor/widgets/common/sliver_delegates.dart';
import 'package:rive_editor/widgets/home/file.dart';
import 'package:rive_editor/widgets/home/folder_view_widget.dart';
import 'package:rive_editor/widgets/home/navigation_panel.dart';
import 'package:rive_editor/widgets/home/team_detail_panel.dart';
import 'package:rive_editor/widgets/home/top_nav.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/notifications.dart';
import 'package:rive_editor/widgets/resize_panel.dart';

const double kFileAspectRatio = kGridWidth / kFileHeight;
const double kFileHeight = 190;
const double kFolderAspectRatio = kGridWidth / kFolderHeight;
const double kFolderHeight = 50;
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
    final theme = RiveTheme.of(context);

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
                  hitSize: theme.dimensions.resizeEdgeSize,
                  direction: ResizeDirection.horizontal,
                  side: ResizeSide.end,
                  min: 252,
                  max: 500,
                  child: NavigationPanel(),
                ),
                Expanded(
                  child: MainPanel(),
                ),
                if (fileBrowser?.owner is RiveTeam)
                  ResizePanel(
                    hitSize: theme.dimensions.resizeEdgeSize,
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

  /// Displayed when a no folder is selected, somehow
  Widget _buildNoFolderSelection(BuildContext context) {
    return const Center(
      child: Text(
        'Please select your user space or any folder\n'
        'in the panel the left side.',
        style: TextStyle(color: Colors.grey),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildNoSelection(BuildContext context) {
    return const Center(
      child: Text(
        'Please select your user space or any team\n'
        'you may be a part of on the left.',
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
        gridDelegate: const SliverGridDelegateFixedSize(
          crossAxisExtent: kGridWidth,
          mainAxisExtent: kFileHeight,
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
        gridDelegate: const SliverGridDelegateFixedSize(
          crossAxisExtent: kGridWidth,
          mainAxisExtent: kFolderHeight,
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

    if (fileBrowser == null) {
      return _buildNoSelection(context);
    }
    return LayoutBuilder(
      builder: (context, dimens) {
        fileBrowser.sizeChanged(dimens);
        final folders =
            fileBrowser.selectedFolder?.children?.cast<RiveFolder>() ?? [];

        if (fileBrowser.selectedFolder == null) {
          return _buildNoFolderSelection(context);
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
                        horizontal: 30, vertical: 30),
                    child: TopNav(fileBrowser),
                  ),
                ),
                if (folders != null && folders.isNotEmpty) ...[
                  _buildFolders(folders, fileBrowser),
                ],
                if (folders != null &&
                    folders.isNotEmpty &&
                    files != null &&
                    files.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  )
                ],
                if (files != null && files.isNotEmpty) ...[
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

class HomeStream extends StatelessWidget {
  const HomeStream({Key key}) : super(key: key);

  bool get isTeam => true;

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    return PropagatingListener(
      behavior: HitTestBehavior.deferToChild,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ResizePanel(
            hitSize: theme.dimensions.resizeEdgeSize,
            direction: ResizeDirection.horizontal,
            side: ResizeSide.end,
            min: 252,
            max: 500,
            child: NavigationPanelStream(),
          ),
          Expanded(
              child: Container(
            color: Colors.greenAccent,
          )),
          if (isTeam)
            ResizePanel(
                hitSize: theme.dimensions.resizeEdgeSize,
                direction: ResizeDirection.horizontal,
                side: ResizeSide.start,
                min: 252,
                max: 500,
                child: Container(color: Colors.blueAccent)
                // child: TeamDetailPanel(team: fileBrowser.owner as RiveTeam),
                ),
        ],
      ),
    );
  }
}
