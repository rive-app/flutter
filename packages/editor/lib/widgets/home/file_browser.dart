import 'dart:math';

import 'package:cursor/propagating_listener.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/plumber.dart';
import 'package:rive_editor/widgets/common/flat_icon_button.dart';
import 'package:rive_editor/widgets/common/labeled_text_field.dart';
import 'package:rive_editor/widgets/common/separator.dart';
import 'package:rive_editor/widgets/common/sliver_delegates.dart';
import 'package:rive_editor/widgets/common/value_stream_builder.dart';
import 'package:rive_editor/widgets/dialog/rive_dialog.dart';
import 'package:rive_editor/widgets/home/file.dart';
import 'package:rive_editor/widgets/home/folder.dart';
import 'package:rive_editor/widgets/home/top_nav.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/popup/context_popup.dart';
import 'package:rive_editor/widgets/popup/list_popup.dart';

typedef FolderContentsBuilder = Widget Function(FolderContents, Selection);

// 50 + 8 for the border.
const double folderCellHeight = 58;
// 182 + 8 for the border.
const double fileCellHeight = 190;
// 187 + 8 for the border.
const double cellWidth = 195;
const double spacing = 22;
const double headerHeight = 60;
const double horizontalPadding = 26;
const double sectionPadding = 30;

class FileBrowserWrapper extends StatefulWidget {
  @override
  _FileBrowserWrapperState createState() => _FileBrowserWrapperState();
}

void editName<T extends Named>(BuildContext context, T target) {
  final colors = RiveTheme.of(context).colors;
  showRiveDialog<void>(
      context: context,
      builder: (ctx) {
        String newName;
        void submit() {
          if (newName != null && newName != target.name) {
            FolderContentsManager().rename(target, newName);
          }
          Navigator.of(context, rootNavigator: true).pop();
        }

        ;
        return SizedBox(
          height: 200,
          width: 400,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LabeledTextField(
                    autofocus: true,
                    label: 'Name',
                    initialValue: target.name,
                    onChanged: (value) => newName = value,
                    onSubmit: (_) => submit(),
                    hintText: 'New name'),
                Expanded(child: Separator(color: colors.fileLineGrey)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FlatIconButton(
                        label: 'Save Changes',
                        color: colors.commonDarkGrey,
                        textColor: Colors.white,
                        onTap: submit)
                  ],
                )
              ],
            ),
          ),
        );
      });
}

class _FileBrowserWrapperState extends State<FileBrowserWrapper> {
  final scrollController = ScrollController();
  final selectionManager = SelectionManager();
  bool rightClick = false;

  int _getMaxColumns(width, cellWidth) {
    return ((width - horizontalPadding * 2 + spacing) / (cellWidth + spacing))
        .floor();
  }

  double _requiredHeight(Size size) {
    // TODO:
    // could cache this against size & file & folder count
    // if this becomes heavy
    var requiredHeight = headerHeight + sectionPadding;
    final directory = Plumber().peek<CurrentDirectory>();
    if (directory == null) return requiredHeight;
    final folderContents = Plumber().peek<FolderContents>(directory.hashId);
    if (folderContents == null) return requiredHeight;

    final int maxColumns = _getMaxColumns(size.width, cellWidth);

    if (folderContents.folders.isNotEmpty) {
      final folderRows = (folderContents.folders.length / maxColumns).ceil();
      final foldersHeight =
          folderRows * folderCellHeight + (folderRows - 1) * spacing;

      requiredHeight += foldersHeight + sectionPadding;
    }
    if (folderContents.files.isNotEmpty) {
      final fileRows = (folderContents.files.length / maxColumns).ceil();
      final filesHeight = fileRows * fileCellHeight + (fileRows - 1) * spacing;

      requiredHeight += filesHeight + sectionPadding;
    }
    return requiredHeight;
  }

  void selectPosition(Offset offset, Size size) {
    final directory = Plumber().peek<CurrentDirectory>();
    if (directory == null) return selectionManager.clearSelection();
    final folderContents = Plumber().peek<FolderContents>(directory.hashId);
    if (folderContents == null) return selectionManager.clearSelection();

    final int maxColumns = _getMaxColumns(size.width, cellWidth);

    var workingDy = offset.dy;
    var workingDx = offset.dx;
    int row;
    int column;
    int elementIndex;

    // add scroll offset
    workingDy += scrollController.offset;
    // remove header
    workingDy -= headerHeight + sectionPadding;
    // remove padding
    workingDx -= horizontalPadding;

    if (workingDx < 0) return selectionManager.clearSelection();
    column = (workingDx / (cellWidth + spacing)).floor();
    // clicked to the right of the target column
    if (workingDx - (column * (cellWidth + spacing)) > cellWidth)
      return selectionManager.clearSelection();
    if (workingDx < 0) return selectionManager.clearSelection();
    if (column + 1 > maxColumns) return selectionManager.clearSelection();

    if (folderContents.folders.isNotEmpty) {
      final folderRows = (folderContents.folders.length / maxColumns).ceil();
      final foldersHeight =
          folderRows * folderCellHeight + (folderRows - 1) * spacing;
      if (workingDy < foldersHeight) {
        // clicked into folders
        row = (workingDy / (folderCellHeight + spacing)).floor();
        // clicked to the right of the target column
        if (workingDy - (row * (folderCellHeight + spacing)) > folderCellHeight)
          return selectionManager.clearSelection();
        elementIndex = row * maxColumns + column;
        if (elementIndex < folderContents.folders.length) {
          return selectionManager
              .selectFolder(folderContents.folders[elementIndex]);
        }
      }
      workingDy -= foldersHeight + sectionPadding;
    }
    if (workingDy < 0) return selectionManager.clearSelection();
    if (folderContents.files.isNotEmpty) {
      final fileRows = (folderContents.files.length / maxColumns).ceil();
      final filesHeight = fileRows * fileCellHeight + (fileRows - 1) * spacing;
      if (workingDy < filesHeight) {
        // clicked into files
        row = (workingDy / (fileCellHeight + spacing)).floor();
        if (workingDy - (row * (fileCellHeight + spacing)) > fileCellHeight)
          return selectionManager.clearSelection();
        elementIndex = row * maxColumns + column;
        if (elementIndex <= folderContents.files.length) {
          return selectionManager
              .selectFile(folderContents.files[elementIndex]);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PropagatingListener(
      onPointerDown: (event) {
        rightClick = false;
        if (event.pointerEvent is PointerDownEvent) {
          selectPosition(event.pointerEvent.localPosition, context.size);

          // TODO: wat this on mouse/ windows
          rightClick = event.pointerEvent.buttons == 2;
        }
      },
      onPointerUp: (event) {
        if (rightClick && Plumber().peek<Selection>() != null) {
          ListPopup.show(context,
              itemBuilder: (popupContext, item, isHovered) =>
                  item.itemBuilder(popupContext, isHovered),
              items: [
                PopupContextItem(
                  'Rename',
                  select: () async {
                    final selection = Plumber().peek<Selection>();
                    if (selection.files.isNotEmpty) {
                      editName(context, selection.files.first);
                    } else if (selection.folders.isNotEmpty) {
                      editName(context, selection.folders.first);
                    }
                  },
                ),
                PopupContextItem(
                  'Delete',
                  select: () async {
                    FolderContentsManager().delete();
                  },
                )
              ],
              position: event.pointerEvent.position);
        }
      },
      onPointerCancel: (event) {
        // print('pointer cancel $event');
      },
      onPointerMove: (event) {
        // print('pointer move $event');
      },
      onPointerSignal: (event) {
        if (event.pointerEvent is PointerScrollEvent) {
          var scrollEvent = event.pointerEvent as PointerScrollEvent;
          var newOffset = scrollController.offset + scrollEvent.scrollDelta.dy;
          newOffset = max(
              0,
              min(_requiredHeight(context.size) - context.size.height,
                  newOffset));
          scrollController.jumpTo(newOffset);
        }
      },
      child: Stack(
        children: [
          FileBrowser(scrollController),
          // IgnorePointer(
          //   child: FileBrowser(scrollController),
          // ),
        ],
      ),
    );
  }
}

class FileBrowser extends StatelessWidget {
  final ScrollController scrollController;

  const FileBrowser(this.scrollController, {Key key}) : super(key: key);

  Widget _folderGrid(Iterable<Folder> folders, Selection selection) {
    return _grid(
      cellHeight: folderCellHeight,
      cellBuilder: SliverChildBuilderDelegate(
        (context, index) {
          var folder = folders.elementAt(index);
          return BrowserFolder(folder.name, folder.id,
              selection?.folders?.contains(folder) == true);
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
        crossAxisExtent: cellWidth, // 187 + 8 of the border.
        mainAxisExtent: cellHeight,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
      ),
      delegate: cellBuilder,
    );
  }

  Widget _fileGrid(Iterable<File> files, Selection selection) {
    return _grid(
      cellHeight: fileCellHeight,
      cellBuilder: SliverChildBuilderDelegate(
        (context, index) {
          var file = files.elementAt(index);
          return ValueStreamBuilder<File>(
              stream: Plumber().getStream<File>(file.hashCode),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                } else {
                  return BrowserFile(snapshot.data,
                      selection?.files?.contains(snapshot.data) == true);
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
    return ValueStreamBuilder<CurrentDirectory>(
      stream: Plumber().getStream<CurrentDirectory>(),
      builder: (context, cdSnapshot) {
        if (cdSnapshot.hasData) {
          final cd = cdSnapshot.data;
          return ValueStreamBuilder<FolderContents>(
            stream: Plumber().getStream<FolderContents>(cd.hashId),
            builder: (context, fcSnapshot) {
              return ValueStreamBuilder<Selection>(
                  stream: Plumber().getStream<Selection>(),
                  builder: (context, selectionSnapshot) {
                    return childBuilder(
                        fcSnapshot.data, selectionSnapshot.data);
                  });
            },
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget _header() {
    return ValueStreamBuilder<CurrentDirectory>(
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
      (data, selection) {
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
              child: SizedBox(height: sectionPadding),
            ),
          );
          if (hasFolders) {
            slivers.add(_folderGrid(folders, selection));
          }

          // Padding between grids.
          if (hasFiles && hasFolders) {
            slivers.add(
              const SliverToBoxAdapter(
                child: SizedBox(height: sectionPadding),
              ),
            );
          }

          if (hasFiles) {
            slivers.add(_fileGrid(files, selection));
          } else {
            // Empty view.
            slivers.add(
              SliverFillRemaining(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Image.asset('assets/images/robot.png'),
                    // const SizedBox(height: 35),
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
            horizontal: horizontalPadding,
          ),
          child: CustomScrollView(
            primary: false,
            controller: scrollController,
            slivers: slivers,
            physics: NeverScrollableScrollPhysics(),
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
  double get maxExtent => headerHeight;

  @override
  double get minExtent => headerHeight;

  @override
  bool shouldRebuild(_SliverHeader oldDelegate) {
    return child != oldDelegate.child;
  }
}
