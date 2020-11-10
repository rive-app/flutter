import 'dart:async';
import 'dart:math';

import 'package:cursor/propagating_listener.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/plumber.dart';
import 'package:rive_editor/widgets/common/flat_icon_button.dart';
import 'package:rive_editor/widgets/common/labeled_text_field.dart';
import 'package:rive_editor/widgets/common/separator.dart';
import 'package:rive_editor/widgets/common/sliver_delegates.dart';
import 'package:rive_editor/widgets/common/underline.dart';
import 'package:rive_editor/widgets/common/value_stream_builder.dart';
import 'package:rive_editor/widgets/dialog/rive_dialog.dart';
import 'package:rive_editor/widgets/home/file.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/theme.dart';
import 'package:rive_editor/widgets/toolbar/connected_users.dart';

const double folderCellHeight = 50;
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

class SimpleFileBrowserWrapper extends StatefulWidget {
  const SimpleFileBrowserWrapper({this.files});
  final Future<Iterable<File>> files;

  @override
  _SimpleFileBrowserWrapperState createState() =>
      _SimpleFileBrowserWrapperState();
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

class _SimpleFileBrowserWrapperState extends State<SimpleFileBrowserWrapper> {
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
  final _files = <File>[];

  @override
  void initState() {
    widget.files.then((fileList) => setState(() => _files.addAll(fileList)));
    super.initState();
  }

  @override
  void dispose() {
    scrollEdgeTimer?.cancel();
    super.dispose();
  }

  int _getMaxColumns(double width, double cellWidth) =>
      ((width - horizontalPadding * 2 + spacing) / (cellWidth + spacing))
          .floor();

  double _sectionHeight(int nrItems, double itemHeight, int maxColumns) {
    if (nrItems > 0) {
      final rows = (nrItems / maxColumns).ceil();
      final height = rows * itemHeight + (rows - 1) * spacing;
      return height + sectionPadding;
    } else {
      return 0;
    }
  }

  double _requiredHeight(Size size, int nrItems) {
    var requiredHeight = headerHeight + sectionPadding;
    final int maxColumns = _getMaxColumns(size.width, cellWidth);
    return requiredHeight + _sectionHeight(nrItems, fileCellHeight, maxColumns);
  }

  void selectMarquee() {
    var startDx = min(marquee.start.dx, marquee.end.dx);
    var startDy = min(marquee.start.dy + startScrollOffset,
        marquee.end.dy + scrollController.offset);
    var endDx = max(marquee.start.dx, marquee.end.dx);
    var endDy = max(marquee.start.dy + startScrollOffset,
        marquee.end.dy + scrollController.offset);

    final int maxColumns = _getMaxColumns(context.size.width, cellWidth);
    startDx -= horizontalPadding;
    endDx -= horizontalPadding;
    startDy -= headerHeight + sectionPadding;
    endDy -= headerHeight + sectionPadding;

    var overlappingColumns =
        getOverlap(maxColumns, cellWidth, spacing, 0, startDx, endDx);

    var fileRowCount = (_files.length / maxColumns).ceil();
    var overlappingFileRows =
        getOverlap(fileRowCount, fileCellHeight, spacing, 0, startDy, endDy);

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

    return selectionManager.select(
      {},
      _filter(_files, fileIndexes).toSet(),
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

    if (_files.isNotEmpty) {
      final fileRows = (_files.length / maxColumns).ceil();
      final filesHeight = fileRows * fileCellHeight + (fileRows - 1) * spacing;
      if (workingDy < filesHeight) {
        // clicked into files
        row = (workingDy / (fileCellHeight + spacing)).floor();
        if (workingDy - (row * (fileCellHeight + spacing)) > fileCellHeight) {
          return null;
        }
        elementIndex = row * maxColumns + column;
        if (elementIndex < _files.length && elementIndex >= 0) {
          return _files[elementIndex];
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
      maxOffset =
          _requiredHeight(context.size, _files.length) - context.size.height;
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
        // var selection = Plumber().peek<Selection>();
        // if (rightClick && selection != null) {
        //   ListPopup.show(context,
        //       itemBuilder: (popupContext, PopupContextItem item, isHovered) =>
        //           item.itemBuilder(popupContext, isHovered),
        //       items: [
        //         if (selection.files.length + selection.folders.length == 1)
        //           PopupContextItem(
        //             'Rename',
        //             select: () async {
        //               final selection = Plumber().peek<Selection>();
        //               if (selection.files.isNotEmpty) {
        //                 editName(context, selection.files.first);
        //               } else if (selection.folders.isNotEmpty) {
        //                 editName(context, selection.folders.first);
        //               }
        //             },
        //           ),
        //         PopupContextItem(
        //           'Delete',
        //           select: () => FolderContentsManager().delete(),
        //         )
        //       ],
        //       position: event.pointerEvent.position);
        // }
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
            min(
                _requiredHeight(context.size, _files.length) -
                    context.size.height,
                newOffset),
          );
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
            child: SimpleFileBrowser(
              files: widget.files,
              scrollController: scrollController,
            ),
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

class SimpleFileBrowser extends StatelessWidget {
  const SimpleFileBrowser({
    this.files,
    this.scrollController,
    Key key,
  }) : super(key: key);
  final Future<Iterable<File>> files;
  final ScrollController scrollController;

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

  // Recents...
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
                return BrowserFile(
                  snapshot.data,
                  selection?.files?.contains(snapshot.data) == true,
                  false,
                );
              }
            },
          );
        },
        childCount: files.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Iterable<File>>(
        future: files,
        builder: (context, filesSnapshot) {
          return ValueStreamBuilder<Selection>(
              stream: Plumber().getStream<Selection>(),
              builder: (context, snapshot) {
                final slivers = <Widget>[];
                // Add header
                slivers.add(SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverHeader(const TopNav()),
                ));

                slivers.add(
                  const SliverToBoxAdapter(
                    child: SizedBox(height: belowHeaderPadding),
                  ),
                );

                filesSnapshot.hasData
                    ? slivers.add(_fileGrid(filesSnapshot.data, snapshot.data))
                    : const SliverToBoxAdapter(child: SizedBox());

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                  ),
                  child: CustomScrollView(
                    // Mount only visible widgets (helps with loading details
                    // too). Most users simply load recents view and click on
                    // something in there, so loading extra data is wasteful.
                    cacheExtent: 0,

                    primary: false,
                    controller: scrollController,
                    slivers: slivers,
                    physics: const NeverScrollableScrollPhysics(),
                  ),
                );
              });
        });
  }
}

/// Header above the files grid
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

class TopNav extends StatelessWidget {
  const TopNav({Key key}) : super(key: key);

  Widget _navControls(BuildContext context) {
    final riveColors = RiveTheme.of(context).colors;
    final styles = RiveTheme.of(context).textStyles;
    final children = <Widget>[];
    const headerName = 'Recents';

    children.add(
      AvatarView(
        diameter: 30,
        borderWidth: 0,
        imageUrl: null,
        name: headerName,
        color: riveColors.accentDarkMagenta,
      ),
    );
    children.add(const SizedBox(width: 9));
    children.add(Text(headerName, style: styles.fileGreyTextLarge));
    children.add(const Spacer());
    return Row(children: children);
  }

  @override
  Widget build(BuildContext context) {
    final riveColors = RiveTheme.of(context).colors;

    return Underline(
      color: riveColors.fileLineGrey,
      child: _navControls(context),
      thickness: 1,
    );
  }
}
