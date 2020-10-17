import 'dart:collection';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:rive_core/animation/keyed_property.dart';
import 'package:rive_core/animation/keyframe.dart';
import 'package:rive_core/animation/linear_animation.dart';
import 'package:rive_editor/rive/managers/animation/animation_time_manager.dart';
import 'package:rive_editor/rive/managers/animation/editing_animation_manager.dart';
import 'package:rive_editor/rive/managers/animation/keyframe_manager.dart';
import 'package:rive_editor/selectable_item.dart';
import 'package:rive_editor/widgets/animation/key_path_maker.dart';
import 'package:rive_editor/widgets/animation/keyed_object_tree_controller.dart';
import 'package:rive_editor/widgets/animation/timeline_keys_manipulator.dart';
import 'package:rive_editor/widgets/animation/timeline_render_box.dart';
import 'package:rive_editor/widgets/common/value_stream_builder.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/theme.dart';
import 'package:tree_widget/flat_tree_item.dart';

/// Draws the rows in the timeline, separators, and their respective keys. Also
/// handles interaction/user input with them.
class TimelineKeys extends StatefulWidget {
  final RiveThemeData theme;
  final ScrollController verticalScroll;
  final KeyedObjectTreeController treeController;
  final EditingAnimationManager animationManager;

  const TimelineKeys({
    @required this.theme,
    @required this.verticalScroll,
    @required this.treeController,
    @required this.animationManager,
    Key key,
  }) : super(key: key);

  @override
  _TimelineKeysState createState() => _TimelineKeysState();
}

class _TimelineKeysState extends State<TimelineKeys> {
  double _scrollOffset = 0;
  List<FlatTreeItem<KeyHierarchyViewModel>> _rows = [];

  @override
  void initState() {
    super.initState();
    widget.verticalScroll?.addListener(_onVerticalScrollChanged);
    _onVerticalScrollChanged();
    widget.treeController?.addListener(_onFlatListChanged);
    _onFlatListChanged();
  }

  @override
  void didUpdateWidget(TimelineKeys oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.verticalScroll != widget.verticalScroll) {
      oldWidget.verticalScroll?.removeListener(_onVerticalScrollChanged);
      widget.verticalScroll?.addListener(_onVerticalScrollChanged);
      _onVerticalScrollChanged();
    }
    if (oldWidget.treeController != widget.treeController) {
      oldWidget.treeController?.removeListener(_onFlatListChanged);
      widget.treeController?.addListener(_onFlatListChanged);
      _onFlatListChanged();
    }
  }

  @override
  void dispose() {
    widget.verticalScroll?.removeListener(_onVerticalScrollChanged);
    super.dispose();
  }

  void _onFlatListChanged() {
    setState(() {
      _rows = widget.treeController.flat ?? [];
    });
  }

  void _onVerticalScrollChanged() {
    if (widget.verticalScroll == null) {
      return;
    }
    setState(() {
      _scrollOffset = widget.verticalScroll.offset;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueStreamBuilder<TimelineViewport>(
      stream: widget.animationManager.viewport,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }
        var viewport = snapshot.data;
        return ValueListenableBuilder(
          valueListenable: ActiveFile.of(context).keyFrameManager,
          builder: (context, KeyFrameManager keyFrameManager, _) =>
              TimelineKeysManipulator(
            activeFile: ActiveFile.of(context),
            viewport: viewport,
            theme: widget.theme,
            verticalScroll: widget.verticalScroll,
            animationManager: widget.animationManager,
            keyFrameManager: keyFrameManager,
            rows: _rows,
            expandedRows: widget.treeController.expanded,
            builder: (context) => ValueStreamBuilder<WorkAreaViewModel>(
              stream: widget.animationManager.workArea,
              builder: (context, workArea) =>
                  ValueStreamBuilder<HashSet<KeyFrame>>(
                stream: keyFrameManager.selection,
                builder: (context, selection) => _TimelineKeysRenderer(
                  theme: widget.theme,
                  verticalScrollOffset: _scrollOffset,
                  rows: _rows,
                  viewport: viewport,
                  animation: widget.animationManager.animation,
                  selection: selection.data,
                  workArea: workArea.hasData ? workArea.data : null,
                  expandedRows: widget.treeController.expanded,
                  repaint: widget.animationManager.hierarchySelectionChanged,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TimelineKeysRenderer extends LeafRenderObjectWidget {
  final RiveThemeData theme;
  final double verticalScrollOffset;
  final List<FlatTreeItem<KeyHierarchyViewModel>> rows;
  final TimelineViewport viewport;
  final LinearAnimation animation;
  final HashSet<KeyFrame> selection;
  final WorkAreaViewModel workArea;
  final HashSet<KeyHierarchyViewModel> expandedRows;
  final Listenable repaint;

  const _TimelineKeysRenderer({
    @required this.theme,
    @required this.verticalScrollOffset,
    @required this.rows,
    @required this.viewport,
    @required this.animation,
    @required this.selection,
    @required this.workArea,
    @required this.expandedRows,
    @required this.repaint,
  });
  @override
  RenderObject createRenderObject(BuildContext context) {
    return _TimelineKeysRenderObject()
      ..theme = theme
      ..verticalScrollOffset = verticalScrollOffset
      ..rows = rows
      ..viewport = viewport
      ..animation = animation
      ..selection = selection
      ..workArea = workArea
      ..expandedRows = expandedRows
      ..repaint = repaint;
  }

  @override
  void updateRenderObject(
      BuildContext context, _TimelineKeysRenderObject renderObject) {
    renderObject
      ..theme = theme
      ..verticalScrollOffset = verticalScrollOffset
      ..rows = rows
      ..viewport = viewport
      ..animation = animation
      ..selection = selection
      ..workArea = workArea
      ..expandedRows = expandedRows
      ..repaint = repaint;
  }

  @override
  void didUnmountRenderObject(
      covariant _TimelineKeysRenderObject renderObject) {
    renderObject.dispose();
  }
}

class _TimelineKeysRenderObject extends TimelineRenderBox {
  final Path fillKeyPath = Path();
  final Path strokeKeyPath = Path();
  final Path fillHoldPath = Path();
  final Path strokeHoldPath = Path();
  final Paint _bgPaint = Paint();
  final Paint _separatorPaint = Paint();
  final Paint _hoveredRowPaint = Paint();
  final Paint _selectedRowPaint = Paint();

  final Paint _keyPaintFill = Paint()..isAntiAlias = false;
  final Paint _keyPaintStroke = Paint()
    ..isAntiAlias = false
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke;
  final Paint _connectKeyPaint = Paint()
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke
    ..isAntiAlias = false;
  final Paint _allkeyFill = Paint()..isAntiAlias = false;
  final Paint _allkeyStroke = Paint()
    ..isAntiAlias = false
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke;
  final Paint _selectedPaint = Paint()
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke
    ..isAntiAlias = false;
  final Paint _workAreaBgPaint = Paint();
  final Paint _workAreaLinePaint = Paint()
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke
    ..isAntiAlias = false;

  double _verticalScrollOffset;
  List<FlatTreeItem<KeyHierarchyViewModel>> _rows;

  Listenable _repaint;
  Listenable get repaint => _repaint;
  set repaint(Listenable value) {
    if (_repaint == value) {
      return;
    }
    _repaint?.removeListener(markNeedsPaint);
    _repaint = value;
    _repaint?.addListener(markNeedsPaint);
  }

  WorkAreaViewModel _workArea;
  WorkAreaViewModel get workArea => _workArea;
  set workArea(WorkAreaViewModel value) {
    if (_workArea == value) {
      return;
    }
    _workArea = value;
    markNeedsPaint();
  }

  HashSet<KeyHierarchyViewModel> _expandedRows;
  HashSet<KeyHierarchyViewModel> get expandedRows => _expandedRows;
  set expandedRows(HashSet<KeyHierarchyViewModel> value) {
    if (_expandedRows == value) {
      return;
    }
    _expandedRows = value;
    markNeedsPaint();
  }

  HashSet<KeyFrame> _selection;
  HashSet<KeyFrame> get selection => _selection;
  set selection(HashSet<KeyFrame> value) {
    if (value == _selection) {
      return;
    }
    _selection = value;
    markNeedsPaint();
  }

  LinearAnimation _animation;
  LinearAnimation get animation => _animation;
  set animation(LinearAnimation value) {
    if (value == _animation) {
      return;
    }
    _animation?.keyframesChanged?.removeListener(markNeedsPaint);
    _animation = value;
    _animation.keyframesChanged.addListener(markNeedsPaint);
  }

  void dispose() {
    _animation?.keyframesChanged?.removeListener(markNeedsPaint);
    _repaint?.removeListener(markNeedsPaint);
  }

  @override
  void onThemeChanged(RiveThemeData theme) {
    _bgPaint.color = theme.colors.timelineBackground;
    _separatorPaint.color = theme.colors.timelineLine;
    _keyPaintFill.color = theme.colors.key;
    _keyPaintStroke.color = theme.colors.key;
    _connectKeyPaint.color = theme.colors.keyLine;
    _allkeyFill.color = theme.colors.allKey;
    _allkeyStroke.color = theme.colors.allKey;
    _selectedPaint.color = theme.colors.keySelection;
    _workAreaBgPaint.color = theme.colors.workAreaBackground;
    _workAreaLinePaint.color = theme.colors.workAreaDelineator;
    _hoveredRowPaint.color = theme.colors.timelineBackgroundHover;
    _selectedRowPaint.color = theme.colors.timelineBackgroundSelected;

    makeStrokeKeyPath(
        strokeKeyPath,
        theme,
        Offset(
            0, (theme.treeStyles.timeline.itemHeight / 2).floorToDouble() - 1));
    makeFillKeyPath(
        fillKeyPath,
        theme,
        Offset(
            0, (theme.treeStyles.timeline.itemHeight / 2).floorToDouble() - 1));

    makeStrokeHoldKeyPath(
        strokeHoldPath,
        theme,
        Offset(
            0, (theme.treeStyles.timeline.itemHeight / 2).floorToDouble() - 1));
    makeFillHoldKeyPath(
        fillHoldPath,
        theme,
        Offset(
            0, (theme.treeStyles.timeline.itemHeight / 2).floorToDouble() - 1));
  }

  double get verticalScrollOffset => _verticalScrollOffset;
  set verticalScrollOffset(double value) {
    if (_verticalScrollOffset == value) {
      return;
    }
    _verticalScrollOffset = value;
    markNeedsPaint();
  }

  List<FlatTreeItem<KeyHierarchyViewModel>> get rows => _rows;
  set rows(List<FlatTreeItem<KeyHierarchyViewModel>> value) {
    if (_rows == value) {
      return;
    }
    _rows = value;
    markNeedsPaint();
  }

  @override
  bool get sizedByParent => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    var canvas = context.canvas;
    canvas.drawRect(offset & size, _bgPaint);
    canvas.save();
    canvas.clipRect(offset & size);

    if (_workArea?.active ?? false) {
      // Using +0.5 as skia seems to draw a line on the half pixel...
      var xStart = framesToPixels(_workArea.start) + 0.5;
      var xEnd = framesToPixels(_workArea.end) + 0.5;

      canvas.drawRect(
          Rect.fromLTRB(xStart, offset.dy, xEnd, offset.dy + size.height),
          _workAreaBgPaint);

      canvas.drawLine(Offset(xStart, offset.dy),
          Offset(xStart, offset.dy + size.height), _workAreaLinePaint);
      canvas.drawLine(Offset(xEnd, offset.dy),
          Offset(xEnd, offset.dy + size.height), _workAreaLinePaint);
    }

    var rowHeight = theme.treeStyles.timeline.itemHeight;

    // Round scroll offset to nearest half pixel.
    var renderScrollOffset = _verticalScrollOffset
        .roundToDouble(); //(_verticalScrollOffset * 2).roundToDouble()/2;
    var firstRow =
        // Can't use truncating divisor as -0.3 ~/ 34 == 0, we always want to floor.
        (renderScrollOffset / rowHeight).floor();
    var renderOffset = renderScrollOffset % rowHeight;
    var visibleRows = (size.height / rowHeight).ceil() + 1;
    var lastRow = (firstRow + visibleRows).clamp(0, _rows.length).toInt();

    // If the first visible row is less than 0, offset our first translation by
    // that many rows and then shift rendering to start at our first item.
    if (firstRow < 0) {
      renderOffset += firstRow * rowHeight;
      firstRow = 0;
    }

    canvas.translate(offset.dx, offset.dy - renderOffset);

    // If we draw past this x position, we can stop drawing as we're effectively
    // off screen. We offset by half the width of the key as key origin is in
    // the center of the key, so anything drawing with an origin of width + half
    // key will not be within the bounds of this widget.
    var lower = theme.dimensions.keyLower;
    var upper = theme.dimensions.keyUpper;
    var rightThreshold = size.width + upper;

    for (int i = firstRow; i < lastRow; i++) {
      var row = _rows[i].data;

      var selection = row.selectionState?.value;
      if (selection != null) {
        switch (selection) {
          case SelectionState.hovered:
          case SelectionState.selected:
            canvas.drawRect(
                Rect.fromLTWH(0, 0, size.width, rowHeight),
                selection == SelectionState.hovered
                    ? _hoveredRowPaint
                    : _selectedRowPaint);
            break;
          default:
            break;
        }
      }
      
      // We only draw the separator line if it's delineating a component.
      if (row is KeyedComponentViewModel) {
        // var rowOffset = i * rowHeight;
        Offset lineStart = const Offset(0.0, -0.5);

        Offset lineEnd = Offset(size.width, -0.5);
        canvas.drawLine(lineStart, lineEnd, _separatorPaint);
      }

      KeyFrameList keyFrameList;

      Paint keyFill;
      Paint keyStroke;
      bool connectKeys = false;
      if (row is KeyedPropertyViewModel) {
        connectKeys = true;
        keyFrameList = row.keyedProperty;
        keyFill = _keyPaintFill;
        keyStroke = _keyPaintStroke;
      } else if (row is AllKeysViewModel) {
        keyFrameList = row.allProperties.cached;
        keyFill = _allkeyFill;
        keyStroke = _allkeyStroke;
        if (_expandedRows.contains(row)) {
          canvas.translate(0, rowHeight);
          continue;
        }
      }

      var lineY = rowHeight / 2 - 1;
      var lastSelected = false;
      if (keyFrameList != null) {
        List<KeyFrameInterface> frames =
            keyFrameList.keyframes as List<KeyFrameInterface>;
        // inxedOfFrame does a binary search on integer frame values so we need
        // to offset the first frame by one to compensate for rounding errors.
        // We end up potentially drawing an extra frame, but the it fixes
        // popping and still culls majority of out of viewport frames.
        var firstFrame = (secondsStart * viewport.fps).floor() - 1;
        // Always draw one back so we can ensure that the lines connect. We do
        // the same for the right hand side (draw one extra).
        var index = max(0, keyFrameList.indexOfFrame(firstFrame) - 1);
        int frameCount = frames.length;
        double lastX = 0;
        if (index < frameCount) {
          lastX = framesToPixels(frames[index].frame);

          canvas.translate(lastX, 0);
          for (int i = index; i < frameCount; i++) {
            var keyFrame = frames[i];
            var x = framesToPixels(keyFrame.frame);

            // We don't just break here as we may want to draw the last
            // connected line for this row even if it's off screen.
            bool isVisible = x <= rightThreshold;

            var move = x - lastX;

            canvas.translate(move, 0);
            lastX = x;

            bool isSelected;
            var renderStroke = strokeKeyPath;
            var renderFill = fillKeyPath;
            var fillPaint = keyFill;

            if (keyFrame is AllKeyFrame) {
              if (isSelected = _selection.containsAll(keyFrame.keyframes)) {
                // When an all key is selected, it should fill like a regular
                // key. #809
                fillPaint = _keyPaintFill;
              }
            } else {
              if ((keyFrame as KeyFrameBase).interpolationType == 0) {
                renderStroke = strokeHoldPath;
                renderFill = fillHoldPath;
              }
              isSelected = _selection.contains(keyFrame);
            }

            // Draw connecting line between keyframes.
            if (connectKeys && i != 0) {
              canvas.drawLine(
                  Offset(-move + upper, lineY),
                  Offset(lower + 1, lineY),
                  isSelected && lastSelected
                      ? _selectedPaint
                      : _connectKeyPaint);
            }

            // Draw the keyframe itself.
            if (fillPaint != null) {
              canvas.drawPath(renderFill, fillPaint);
            }

            // we always paint stroke as we use it to fix up our fill for the
            // weird skia antialiasing issue
            canvas.drawPath(
                renderStroke, isSelected ? _selectedPaint : keyStroke);

            if (!isVisible) {
              break;
            }

            lastSelected = isSelected;
          }
        }
        canvas.translate(-lastX, 0);
      }

      canvas.translate(0, rowHeight);
    }

    canvas.restore();
  }
}
