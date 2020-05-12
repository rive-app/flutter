import 'package:flutter/material.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/plumber.dart';
import 'package:rive_editor/widgets/common/sliver_delegates.dart';
import 'package:rive_editor/widgets/home/file.dart';
import 'package:rive_editor/widgets/home/folder.dart';
import 'package:rive_editor/widgets/home/top_nav.dart';

typedef FolderContentsBuilder = Widget Function(FolderContents);

class FileBrowser extends StatelessWidget {
  const FileBrowser();

  Widget _folderGrid(Iterable<Folder> folders) {
    return _grid(
      cellHeight: 50,
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
        crossAxisExtent: 187,
        mainAxisExtent: cellHeight,
        mainAxisSpacing: 30,
        crossAxisSpacing: 30,
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
              stream: Plumber().getStream<File>('${file.id}'),
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

  Widget _stream(FolderContentsBuilder childBuilder) {
    return StreamBuilder<FolderContents>(
      stream: Plumber().getStream<FolderContents>(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return childBuilder(snapshot.data);
        } else {
          print("Progress indicator");
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget _header() {
    return StreamBuilder<CurrentDirectory>(
      stream: Plumber().getStream<CurrentDirectory>(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: TopNavStream(snapshot.data),
            ),
          );
        } else {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: 30),
              child: Text('No directory selected?'),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _stream(
      (data) {
        final folders = data.folders;
        final hasFolders = folders != null && folders.isNotEmpty;

        final files = data.files;
        final hasFiles = files != null && files.isNotEmpty;

        final slivers = <Widget>[];
        slivers.add(_header());
        if (hasFolders) {
          slivers.add(_folderGrid(folders));
        }

        // Padding in between grids.
        if (hasFiles && hasFolders) {
          slivers.add(
            const SliverToBoxAdapter(
              child: SizedBox(height: 30),
            ),
          );
        }

        if (hasFiles) {
          slivers.add(_fileGrid(files));
        }

        return Padding(
          padding: const EdgeInsets.all(30.0),
          child: CustomScrollView(
            shrinkWrap: true,
            slivers: slivers,
          ),
        );
      },
    );
  }
}
