import 'package:flutter/material.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/plumber.dart';
import 'package:rive_editor/widgets/common/sliver_delegates.dart';
import 'package:rive_editor/widgets/home/file.dart';
import 'package:rive_editor/widgets/home/folder.dart';
import 'package:rive_editor/widgets/home/top_nav.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

typedef FolderContentsBuilder = Widget Function(FolderContents);

class FileBrowser extends StatelessWidget {
  const FileBrowser();

  Widget _folderGrid(Iterable<Folder> folders) {
    return _grid(
      cellHeight: 58, // 50 + 8 for the border.
      cellBuilder: SliverChildBuilderDelegate(
        (context, index) {
          var folder = folders.elementAt(index);
          return BrowserFolder(folder.name, folder.id);
        },
        childCount: folders.length,
      ),
    );
  }

  Widget _grid({
    @required double cellHeight,
    @required SliverChildBuilderDelegate cellBuilder,
  }) {
    return SliverGrid(
      gridDelegate: SliverGridDelegateFixedSize(
        crossAxisExtent: 195, // 187 + 8 of the border.
        mainAxisExtent: cellHeight,
        mainAxisSpacing: 22,
        crossAxisSpacing: 22,
      ),
      delegate: cellBuilder,
    );
  }

  Widget _fileGrid(Iterable<File> files) {
    return _grid(
      cellHeight: 190,
      cellBuilder: SliverChildBuilderDelegate(
        (context, index) {
          var file = files.elementAt(index);
          return StreamBuilder<File>(
              stream: Plumber().getStream<File>(file.hashCode),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                } else {
                  return BrowserFile(snapshot.data);
                }
              });
        },
        childCount: files.length,
      ),
    );
  }

  bool canDisplayFolder(FolderContents folder) =>
      folder != null && !folder.isLoading;

  Widget _stream(FolderContentsBuilder childBuilder) {
    return StreamBuilder<CurrentDirectory>(
      stream: Plumber().getStream<CurrentDirectory>(),
      builder: (context, cdSnapshot) {
        if (cdSnapshot.hasData) {
          final cd = cdSnapshot.data;
          return StreamBuilder<FolderContents>(
            stream: Plumber().getStream<FolderContents>(cd.hashId),
            builder: (context, fcSnapshot) {
              return childBuilder(fcSnapshot.data);
            },
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget _header() {
    return StreamBuilder<CurrentDirectory>(
      stream: Plumber().getStream<CurrentDirectory>(),
      builder: (context, snapshot) {
        Widget child;
        if (snapshot.hasData) {
          child = TopNav(snapshot.data);
        } else {
          child = const Text('No directory selected?');
        }

        return SliverPersistentHeader(
          pinned: true,
          delegate: _SliverHeader(child),
        );
      },
    );
  }

  SliverPersistentHeader makeHeader(String headerText) {
    return SliverPersistentHeader(
      pinned: true,
      floating: false,
      delegate: _SliverHeader(
        Container(
          color: Colors.lightBlue,
          child: Center(
            child: Text(headerText),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _stream(
      (data) {
        final slivers = <Widget>[];
        slivers.add(_header());

        if (canDisplayFolder(data)) {
          final folders = data.folders;
          final hasFolders = folders != null && folders.isNotEmpty;

          final files = data.files;
          final hasFiles = files != null && files.isNotEmpty;

          // Padding below header.
          slivers.add(
            const SliverToBoxAdapter(
              child: SizedBox(height: 30),
            ),
          );
          if (hasFolders) {
            slivers.add(_folderGrid(folders));
          }

          // Padding between grids.
          if (hasFiles && hasFolders) {
            slivers.add(
              const SliverToBoxAdapter(
                child: SizedBox(height: 30),
              ),
            );
          }

          if (hasFiles) {
            slivers.add(_fileGrid(files));
          } else {
            // Empty view.
            slivers.add(
              SliverFillRemaining(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/robot.png'),
                    const SizedBox(height: 35),
                    Text(
                        'Hey, it looks like you don\'t have any files here '
                        'yet!\nHit the plus button to create a new file!',
                        style: RiveTheme.of(context).textStyles.fileBrowserText,
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }
        } else {
          slivers.add(
            const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator())),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 26,
          ),
          child: CustomScrollView(
            slivers: slivers,
          ),
        );
      },
    );
  }
}

class _SliverHeader extends SliverPersistentHeaderDelegate {
  _SliverHeader(this.child);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      height: double.infinity,
      width: double.infinity,
      color: RiveTheme.of(context).colors.fileBrowserBackground,
      child: child,
    );
  }

  final Widget child;

  @override
  double get maxExtent => 60;

  @override
  double get minExtent => 60;

  @override
  bool shouldRebuild(_SliverHeader oldDelegate) {
    return child != oldDelegate.child;
  }
}
