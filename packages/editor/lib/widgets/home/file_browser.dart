import 'dart:async';
import 'dart:math';

import 'package:cursor/propagating_listener.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/models/team_role.dart';
import 'package:rive_api/plumber.dart';
import 'package:rive_editor/rive/managers/rive_manager.dart';
import 'package:rive_editor/widgets/common/flat_icon_button.dart';
import 'package:rive_editor/widgets/common/labeled_text_field.dart';
import 'package:rive_editor/widgets/common/robot.dart';
import 'package:rive_editor/widgets/common/separator.dart';
import 'package:rive_editor/widgets/common/sliver_delegates.dart';
import 'package:rive_editor/widgets/common/value_stream_builder.dart';
import 'package:rive_editor/widgets/dialog/rive_dialog.dart';
import 'package:rive_editor/widgets/dialog/team_settings/settings_panel.dart';
import 'package:rive_editor/widgets/home/file.dart';
import 'package:rive_editor/widgets/home/folder.dart';
import 'package:rive_editor/widgets/home/top_nav.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/popup/context_popup.dart';
import 'package:rive_editor/widgets/popup/list_popup.dart';
import 'package:rive_editor/widgets/theme.dart';

typedef FolderContentsBuilder = Widget Function(FolderContents, Selection);

const double folderCellHeight =
    58; //Should be 50 but had to add an extra 8 to account for the padding added by the 4px border when selected
const double fileCellHeight = 182;
const double cellWidth = 187;
const double spacing = 22;
const double headerHeight = 60;
const double horizontalPadding = 30;
const double sectionPadding = 22;
const double belowHeaderPadding = 26;
const int scrollEdgeMilliseconds = 1000 ~/ 60;
const double scrollSensitivity = 75;
const double scrollStrength = 6;
const double selectedWidth = 4;

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
  Marquee marquee;
  Rect bounds;
  Size latestSize;

  double maxOffset;
  double edgeOffset = 0;
  double startScrollOffset;
  double endScrollOffset;
  Offset start;
  Offset end;
  Timer scrollEdgeTimer;

  @override
  void dispose() {
    scrollEdgeTimer?.cancel();
    super.dispose();
  }

  int _getMaxColumns(double width, double cellWidth) =>
      ((width - horizontalPadding * 2 + spacing) / (cellWidth + spacing))
          .floor();

  double _sectionHeight(Iterable items, double itemHeight, int maxColumns) {
    if (items.isNotEmpty) {
      final rows = (items.length / maxColumns).ceil();
      final height = rows * itemHeight + (rows - 1) * spacing;
      return height + sectionPadding;
    } else {
      return 0;
    }
  }

  double _requiredHeight(Size size) {
    var requiredHeight = headerHeight + sectionPadding;
    final directory = Plumber().peek<CurrentDirectory>();
    if (directory == null) return requiredHeight;
    final folderContents = Plumber().peek<FolderContents>(directory.hashId);
    if (folderContents == null) return requiredHeight;

    final int maxColumns = _getMaxColumns(size.width, cellWidth);
    requiredHeight +=
        _sectionHeight(folderContents.folders, folderCellHeight, maxColumns);
    requiredHeight +=
        _sectionHeight(folderContents.files, fileCellHeight, maxColumns);
    return requiredHeight;
  }

  void selectMarquee() {
    var startDx = min(marquee.start.dx, marquee.end.dx);
    var startDy = min(marquee.start.dy + startScrollOffset,
        marquee.end.dy + scrollController.offset);
    var endDx = max(marquee.start.dx, marquee.end.dx);
    var endDy = max(marquee.start.dy + startScrollOffset,
        marquee.end.dy + scrollController.offset);

    final directory = Plumber().peek<CurrentDirectory>();
    if (directory == null) return selectionManager.clearSelection();
    final folderContents = Plumber().peek<FolderContents>(directory.hashId);
    if (folderContents == null) return selectionManager.clearSelection();

    final int maxColumns = _getMaxColumns(context.size.width, cellWidth);
    startDx -= horizontalPadding;
    endDx -= horizontalPadding;
    startDy -= headerHeight + sectionPadding + selectedWidth;
    endDy -= headerHeight + sectionPadding + selectedWidth;

    var overlappingColumns =
        getOverlap(maxColumns, cellWidth, spacing, 0, startDx, endDx);

    var folderRowCount = (folderContents.folders.length / maxColumns).ceil();
    var overlappingFolderRows = getOverlap(
        folderRowCount, folderCellHeight, spacing, 0, startDy, endDy);
    var fileRowCount = (folderContents.files.length / maxColumns).ceil();
    var folderRowsHeight =
        _sectionHeight(folderContents.folders, folderCellHeight, maxColumns);
    var overlappingFileRows = getOverlap(fileRowCount, fileCellHeight, spacing,
        folderRowsHeight, startDy, endDy);

    var folderIndexes = {
      for (var columnIndex in overlappingColumns)
        for (var rowIndex in overlappingFolderRows)
          columnIndex + maxColumns * rowIndex
    };

    var fileIndexes = {
      for (var columnIndex in overlappingColumns)
        for (var rowIndex in overlappingFileRows)
          columnIndex + maxColumns * rowIndex
    };

    Iterable<T> _filter<T>(Iterable<T> items, Set<int> indexes) sync* {
      var i = 0;
      for (final item in items) {
        if (indexes.contains(i)) {
          yield item;
        }
        i++;
      }
    }

    folderContents.folders.where((element) => false);

    return selectionManager.select(
      _filter(folderContents.folders, folderIndexes).toSet(),
      _filter(folderContents.files, fileIndexes).toSet(),
    );
  }

  List<int> getOverlap(
    int sequenceCount,
    double sequenceWidth,
    double sequenceSpacing,
    double offset,
    double start,
    double end,
  ) {
    List<List<double>> columns = [];
    double _offset = offset;
    for (var i = 0; i < sequenceCount; i++) {
      columns.add([_offset, _offset + sequenceWidth]);
      _offset = _offset + sequenceWidth + sequenceSpacing;
    }
    var matchedColumns = columns.where((element) =>
        (element[0] <= start && start <= element[1]) ||
        (start <= element[0] && element[0] <= end));
    return matchedColumns.map((e) => columns.indexOf(e)).toList();
  }

  dynamic getPosition(Offset offset, Size size) {
    final directory = Plumber().peek<CurrentDirectory>();
    if (directory == null) return;
    final folderContents = Plumber().peek<FolderContents>(directory.hashId);
    if (folderContents == null) return;

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

    if (workingDx < 0) return null;
    column = (workingDx / (cellWidth + spacing)).floor();
    // clicked to the right of the target column
    if (workingDx - (column * (cellWidth + spacing)) > cellWidth) return null;
    if (workingDx < 0) return null;
    if (column + 1 > maxColumns) return null;

    if (folderContents.folders.isNotEmpty) {
      final folderRows = (folderContents.folders.length / maxColumns).ceil();
      final foldersHeight =
          folderRows * folderCellHeight + (folderRows - 1) * spacing;
      if (workingDy < foldersHeight) {
        // clicked into folders
        row = (workingDy / (folderCellHeight + spacing)).floor();
        // clicked to the right of the target column
        if (workingDy - (row * (folderCellHeight + spacing)) >
            folderCellHeight) {
          return null;
        }
        elementIndex = row * maxColumns + column;
        if (elementIndex < 0) {
          return null;
        }
        if (elementIndex < folderContents.folders.length) {
          return folderContents.folders[elementIndex];
        }
      }
      workingDy -= foldersHeight + sectionPadding;
    }
    if (workingDy < 0) return null;
    if (folderContents.files.isNotEmpty) {
      final fileRows = (folderContents.files.length / maxColumns).ceil();
      final filesHeight = fileRows * fileCellHeight + (fileRows - 1) * spacing;
      if (workingDy < filesHeight) {
        // clicked into files
        row = (workingDy / (fileCellHeight + spacing)).floor();
        if (workingDy - (row * (fileCellHeight + spacing)) > fileCellHeight) {
          return null;
        }
        elementIndex = row * maxColumns + column;
        if (elementIndex < folderContents.files.length) {
          return folderContents.files[elementIndex];
        }
      }
    }
  }

  void selectPosition(Offset offset, Size size, bool rightClick) {
    var selection = Plumber().peek<Selection>() ?? Selection();
    dynamic fileFolder = getPosition(offset, size);

    if (fileFolder is File) {
      if (!rightClick) {
        selectionManager.selectFile(fileFolder);
      } else if (!selection.files.contains(fileFolder)) {
        // if you right click out of selection, you're making a new selection
        selectionManager.selectFile(fileFolder);
      }
    } else if (fileFolder is Folder) {
      if (!rightClick) {
        selectionManager.selectFolder(fileFolder);
      } else if (!selection.folders.contains(fileFolder)) {
        // if you right click out of selection, you're making a new selection
        selectionManager.selectFolder(fileFolder);
      }
    } else {
      if (!rightClick) {
        // if you right click on nothing, we ignore it.
        selectionManager.clearSelection();
      }
    }
  }

  void updateMarquee() {
    setState(() {
      if (start != null && end != null) {
        bounds = Rect.fromLTWH(0, headerHeight, context.size.width,
            context.size.height - headerHeight);
        marquee = Marquee(
          start: start,
          end: end,
          startOffset: startScrollOffset,
          endOffset: scrollController.offset,
        );
      } else {
        marquee = null;
        stopTimer();
      }
    });
    if (marquee != null) {
      var offsetUp = _offset(
          marquee.end.dy, bounds.top, scrollSensitivity, scrollStrength);
      var offsetDown = _offset(
          bounds.bottom, marquee.end.dy, scrollSensitivity, scrollStrength);
      maxOffset = _requiredHeight(context.size) - context.size.height;
      if (offsetUp != 0) {
        edgeOffset = -offsetUp;
        startTimer();
      } else if (offsetDown != 0) {
        edgeOffset = offsetDown;
        startTimer();
      } else {
        edgeOffset = 0;
        stopTimer();
      }
    }
  }

  void startTimer() => scrollEdgeTimer ??= Timer.periodic(
      const Duration(milliseconds: scrollEdgeMilliseconds), scrollEdge);

  void stopTimer() {
    scrollEdgeTimer?.cancel();
    scrollEdgeTimer = null;
  }

  void scrollEdge(Timer timer) {
    if (edgeOffset == 0) {
      stopTimer();
    } else {
      scrollController
          .jumpTo(max(0, min(maxOffset, scrollController.offset + edgeOffset)));
      updateMarquee();
      selectMarquee();
    }
  }

  double _offset(
      double greater, double smaller, double proximity, double extent) {
    if (greater - smaller < proximity) {
      return extent * (proximity - (greater - smaller)) / proximity;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return PropagatingListener(
      onPointerDown: (event) {
        latestSize = context.size;
        rightClick = false;
        if (event.pointerEvent is PointerDownEvent) {
          rightClick = event.pointerEvent.buttons == 2;

          selectPosition(
              event.pointerEvent.localPosition, latestSize, rightClick);

          if (!rightClick) {
            start = event.pointerEvent.localPosition;
            startScrollOffset = scrollController.offset;
            end = null;
          }
          updateMarquee();
        }
      },
      onPointerUp: (event) {
        latestSize = context.size;
        start = null;
        end = null;
        endScrollOffset = null;
        startScrollOffset = null;
        updateMarquee();
        var selection = Plumber().peek<Selection>() ?? Selection();
        var currentDirectory = Plumber().peek<CurrentDirectory>();
        if (rightClick && selection != null) {
          ListPopup.show(context,
              margin: 5,
              itemBuilder: (popupContext, PopupContextItem item, isHovered) =>
                  item.itemBuilder(popupContext, isHovered),
              items: [
                PopupContextItem(
                  'Export',
                  select: () => RiveManager().export(),
                  leftMargin: 15,
                  height: 35,
                ),
                PopupContextItem.separator(),
                if (selection.files.length + selection.folders.length == 1)
                  PopupContextItem(
                    'Rename',
                    select: () async {
                      final selection =
                          Plumber().peek<Selection>() ?? Selection();
                      if (selection.files.isNotEmpty) {
                        final file = Plumber()
                            .peek<File>(selection.files.first.hashCode);
                        editName(context, file);
                      } else if (selection.folders.isNotEmpty) {
                        editName(context, selection.folders.first);
                      }
                    },
                    leftMargin: 15,
                    height: 35,
                  ),
                if (!(currentDirectory?.folder?.isTrash ?? false))
                  PopupContextItem(
                    'Delete',
                    select: () => FolderContentsManager().delete(),
                    leftMargin: 15,
                    height: 35,
                  ),
                if (selection.files.length == 1) PopupContextItem.separator(),
                if (selection.files.length == 1)
                  PopupContextItem(
                    'ID: ${selection.files.first.fileOwnerId}-${selection.files.first.id}',
                    select: () {
                      Clipboard.setData(ClipboardData(
                          text: '${selection.files.first.fileOwnerId}-'
                              '${selection.files.first.id}'));

                      // makes it easy for devs to copy from terminal...
                      print(
                          'ID: ${selection.files.first.fileOwnerId}-${selection.files.first.id}');
                    },
                    leftMargin: 15,
                    height: 35,
                  ),
              ],
              position: event.pointerEvent.position);
        }
      },
      onPointerCancel: (event) {
        latestSize = context.size;
        start = null;
        startScrollOffset = null;
        end = null;
        endScrollOffset = null;
        updateMarquee();
        //
      },
      onPointerMove: (event) {
        latestSize = context.size;
        end = event.pointerEvent.localPosition;
        updateMarquee();
        if (start != null) {
          selectMarquee();
        }
      },
      onPointerSignal: (event) {
        latestSize = context.size;
        end = event.pointerEvent.localPosition;
        if (event.pointerEvent is PointerScrollEvent) {
          var scrollEvent = event.pointerEvent as PointerScrollEvent;
          var newOffset = scrollController.offset + scrollEvent.scrollDelta.dy;
          newOffset = max(
              0,
              min(_requiredHeight(context.size) - context.size.height,
                  newOffset));
          scrollController.jumpTo(newOffset);
          updateMarquee();
          if (start != null) {
            selectMarquee();
          }
        }
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: FileBrowser(scrollController),
          ),
          Positioned.fill(
            child: MarqueeRenderer(
              theme: RiveTheme.of(context),
              verticalScrollOffset: 0, //scrollController.offset,
              bounds: bounds,
              marquee: marquee,
            ),
          ),
        ],
      ),
    );
  }
}

@immutable
class Marquee {
  final Offset start;
  final Offset end;
  final double startOffset;
  final double endOffset;

  const Marquee({this.start, this.end, this.startOffset, this.endOffset});

  @override
  String toString() => 'Marquee($start, $end, $startOffset, $endOffset)';
}

/// Draws the marquee.
class MarqueeRenderer extends LeafRenderObjectWidget {
  final RiveThemeData theme;
  final double verticalScrollOffset;
  final Marquee marquee;
  final Rect bounds;

  const MarqueeRenderer({
    @required this.theme,
    @required this.verticalScrollOffset,
    @required this.marquee,
    @required this.bounds,
  });
  @override
  RenderObject createRenderObject(BuildContext context) {
    return MarqueeRenderObject()
      ..theme = theme
      ..verticalScrollOffset = verticalScrollOffset
      ..marquee = marquee
      ..bounds = bounds;
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant MarqueeRenderObject renderObject) {
    renderObject
      ..theme = theme
      ..verticalScrollOffset = verticalScrollOffset
      ..marquee = marquee
      ..bounds = bounds;
  }
}

class MarqueeRenderObject extends RenderBox {
  final Paint _stroke = Paint()
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke;
  final Paint _fill = Paint();
  RiveThemeData _theme;
  Rect bounds;

  RiveThemeData get theme => _theme;
  set theme(RiveThemeData theme) {
    _theme = theme;
    onThemeChanged(theme);
  }

  // We compute our own range as the one given by the viewport is padded, we
  // actually need to draw a little more than the viewport.
  double _verticalScrollOffset;

  MarqueeRenderObject();
  double get verticalScrollOffset => _verticalScrollOffset;
  set verticalScrollOffset(double value) {
    if (_verticalScrollOffset == value) {
      return;
    }
    _verticalScrollOffset = value;
    markNeedsPaint();
  }

  Marquee _marquee;
  Marquee get marquee => _marquee;
  set marquee(Marquee value) {
    if (value == _marquee) {
      return;
    }
    _marquee = value;
    markNeedsPaint();
  }

  void onThemeChanged(RiveThemeData theme) {
    _stroke.color = theme.colors.keyMarqueeStroke;
    _fill.color = theme.colors.keyMarqueeFill;
  }

  @override
  bool get sizedByParent => true;

  double get startX {
    return max(bounds.left, min(bounds.right, marquee.start.dx));
  }

  double get endX {
    return max(bounds.left, min(bounds.right, marquee.end.dx));
  }

  double get startY {
    return max(
        bounds.top,
        min(bounds.bottom,
            marquee.start.dy + (marquee.startOffset - marquee.endOffset)));
  }

  double get endY {
    return max(bounds.top, min(bounds.bottom, marquee.end.dy));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_marquee == null) {
      return;
    }
    var canvas = context.canvas;
    canvas.save();
    canvas.clipRect(offset & size);
    canvas.translate(offset.dx, offset.dy);

    var rect = Rect.fromLTRB(startX, startY, endX, endY);
    canvas.drawRect(rect, _fill);
    canvas.drawRect(rect, _stroke);
    canvas.restore();
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
          return BrowserFolder(
            folder,
            selection?.folders?.contains(folder) == true,
          );
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

  Widget _fileGrid(Iterable<File> files, Selection selection, bool suspended) {
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
                return BrowserFile(
                  snapshot.data,
                  selection?.files?.contains(snapshot.data) == true,
                  suspended,
                );
              }
            },
          );
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

  @override
  Widget build(BuildContext context) {
    return _stream(
      (data, selection) {
        final currentDirectory = Plumber().peek<CurrentDirectory>();

        final suspended = currentDirectory.owner is Team &&
            (currentDirectory.owner as Team).status == TeamStatus.suspended;

        final failedPayment = currentDirectory.owner is Team &&
            (currentDirectory.owner as Team).status == TeamStatus.failedPayment;

        if (suspended) {
          if (canEditTeam((currentDirectory.owner as Team).permission)) {
            Plumber().message(GlobalMessage(
                'Team suspended',
                'Re-activate',
                () => showSettings(currentDirectory.owner,
                    context: context, initialPanel: SettingsPanel.plan)));
          } else {
            Plumber().message(GlobalMessage(
                'Team suspended. Contact an admin to re-activate.'));
          }
        } else if (failedPayment) {
          if (canEditTeam((currentDirectory.owner as Team).permission)) {
            Plumber().message(GlobalMessage(
                'There was a payment issue.',
                'Update details',
                () => showSettings(currentDirectory.owner,
                    context: context, initialPanel: SettingsPanel.plan)));
          }
        }

        final slivers = <Widget>[];
        slivers.add(_header());

        if (canDisplayFolder(data)) {
          final folders = data.folders;
          final hasFolders = folders?.isNotEmpty == true;

          final files = data.files;
          final hasFiles = files?.isNotEmpty == true;

          // Padding below header.
          slivers.add(
            const SliverToBoxAdapter(
              child: SizedBox(height: belowHeaderPadding),
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
            slivers.add(_fileGrid(files, selection, suspended));
            slivers.add(
              const SliverToBoxAdapter(
                child: SizedBox(height: sectionPadding),
              ),
            );
          } else {
            // Empty view.
            slivers.add(
              SliverFillRemaining(
                child: Center(
                  child: SizedBox(
                    height: 600,
                    child: Stack(
                      children: [
                        const Robot(),
                        Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 0.0),
                              child: Text(
                                  'Hey, it looks like you don\'t '
                                  'have any files here yet!\n'
                                  'Hit the plus button to create a new file.',
                                  style: RiveTheme.of(context)
                                      .textStyles
                                      .fileBrowserText,
                                  textAlign: TextAlign.center),
                            ))
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        } else {
          slivers.add(
            const SliverFillRemaining(
              child: Center(
                child: SizedBox(),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: horizontalPadding,
          ),
          child: CustomScrollView(
            // don't mount widgets out of view at all
            cacheExtent: 0,

            primary: false,
            controller: scrollController,
            slivers: slivers,
            physics: const NeverScrollableScrollPhysics(),
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
    final colors = RiveTheme.of(context).colors;
    return Container(
      height: double.infinity,
      width: double.infinity,
      color: colors.fileBrowserBackground,
      child: child,
    );
  }

  final Widget child;

  @override
  double get maxExtent => headerHeight;

  @override
  double get minExtent => headerHeight;

  @override
  bool shouldRebuild(_SliverHeader oldDelegate) => child != oldDelegate.child;
}
