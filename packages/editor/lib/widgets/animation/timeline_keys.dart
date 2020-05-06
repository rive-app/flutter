import 'dart:collection';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:rive_core/animation/keyed_property.dart';
import 'package:rive_core/animation/keyframe.dart';
import 'package:rive_core/animation/linear_animation.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_editor/rive/managers/animation/animation_time_manager.dart';
import 'package:rive_editor/rive/managers/animation/editing_animation_manager.dart';
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
        return TimelineKeysManipulator(
          activeFile: ActiveFile.of(context),
          viewport: viewport,
          theme: widget.theme,
          verticalScroll: widget.verticalScroll,
          animationManager: widget.animationManager,
          rows: _rows,
          builder: (context, selection) => _TimelineKeysRenderer(
            theme: widget.theme,
            verticalScrollOffset: _scrollOffset,
            rows: _rows,
            viewport: viewport,
            animation: widget.animationManager.animation,
            selection: selection,
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
  const _TimelineKeysRenderer({
    @required this.theme,
    @required this.verticalScrollOffset,
    @required this.rows,
    @required this.viewport,
    @required this.animation,
    @required this.selection,
  });
  @override
  RenderObject createRenderObject(BuildContext context) {
    return _TimelineKeysRenderObject()
      ..theme = theme
      ..verticalScrollOffset = verticalScrollOffset
      ..rows = rows
      ..viewport = viewport
      ..animation = animation
      ..selection = selection;
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant _TimelineKeysRenderObject renderObject) {
    renderObject
      ..theme = theme
      ..verticalScrollOffset = verticalScrollOffset
      ..rows = rows
      ..viewport = viewport
      ..animation = animation
      ..selection = selection;
    ;
  }

  @override
  void didUnmountRenderObject(
      covariant _TimelineKeysRenderObject renderObject) {
    renderObject.dispose();
  }
}

class _TimelineKeysRenderObject extends TimelineRenderBox with KeyPathMaker {
  final Paint _bgPaint = Paint();
  final Paint _separatorPaint = Paint();
  final Paint _keyPaint = Paint();
  final Paint _connectKeyPaint = Paint()
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke;
  final Paint _allkeyPaint = Paint();
  final Paint _selectedPaint = Paint()
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke;

  // We compute our own range as the one given by the viewport is padded, we
  // actually need to draw a little more than the viewport.
  double _secondsStart = 0;

  double _verticalScrollOffset;
  List<FlatTreeItem<KeyHierarchyViewModel>> _rows;

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
  }

  @override
  void onThemeChanged(RiveThemeData theme) {
    _bgPaint.color = theme.colors.timelineBackground;
    _separatorPaint.color = theme.colors.timelineLine;
    _keyPaint.color = theme.colors.key;
    _connectKeyPaint.color = theme.colors.keyLine;
    _allkeyPaint.color = theme.colors.allKey;
    _selectedPaint.color = theme.colors.keySelection;

    makeKeyPath(theme, Offset(0, theme.treeStyles.timeline.itemHeight / 2));
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
  void performLayout() {
    super.performLayout();

    // We use layout to compute some of the constants for this viewport.
    var marginLeft = theme.dimensions.timelineMarginLeft;

    // This is the time at local x 0
    _secondsStart = viewport.startSeconds - marginLeft * secondsPerPixel;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    var canvas = context.canvas;
    canvas.drawRect(offset & size, _bgPaint);
    canvas.save();
    canvas.clipRect(offset & size);

    var rowHeight = theme.treeStyles.timeline.itemHeight;

    var firstRow =
        // Can't use truncating divisor as -0.3 ~/ 34 == 0, we always want to floor.
        (_verticalScrollOffset / rowHeight).floor();
    var renderOffset = _verticalScrollOffset % rowHeight;
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
    var halfBounds = theme.dimensions.keyHalfBounds;
    var rightThreshold = size.width + halfBounds;

    for (int i = firstRow; i < lastRow; i++) {
      var row = _rows[i].data;

      // We only draw the separator line if it's delineating a component.
      if (row is KeyedComponentViewModel) {
        // var rowOffset = i * rowHeight;
        Offset lineStart = const Offset(0.0, -0.5);

        Offset lineEnd = Offset(size.width, -0.5);
        canvas.drawLine(lineStart, lineEnd, _separatorPaint);
      }

      KeyFrameList keyFrameList;

      Paint keyPaint;
      bool connectKeys = false;
      if (row is KeyedPropertyViewModel) {
        connectKeys = true;
        keyFrameList = row.keyedProperty;
        keyPaint = _keyPaint;
      } else if (row is AllKeysViewModel) {
        keyFrameList = row.allProperties.cached;
        keyPaint = _allkeyPaint;
      }

      var halfRowHeight = rowHeight / 2;
      var lastSelected = false;
      if (keyFrameList != null) {
        List<KeyFrameInterface> frames =
            keyFrameList.keyframes as List<KeyFrameInterface>;
        // inxedOfFrame does a binary search on integer frame values so we need
        // to offset the first frame by one to compensate for rounding errors.
        // We end up potentially drawing an extra frame, but the it fixes
        // popping and still culls majority of out of viewport frames.
        var firstFrame = (_secondsStart * viewport.fps).floor() - 1;
        // Always draw one back so we can ensure that the lines connect. We do
        // the same for the right hand side (draw one extra).
        var index = max(0, keyFrameList.indexOfFrame(firstFrame) - 1);
        int frameCount = frames.length;
        var fps = viewport.fps;
        double lastX = 0;
        if (index < frameCount) {
          lastX = (frames[index].frame / fps - _secondsStart) / secondsPerPixel;
          canvas.translate(lastX, 0);
          for (int i = index; i < frameCount; i++) {
            var keyFrame = frames[i];
            var x = (keyFrame.frame / fps - _secondsStart) / secondsPerPixel;

            // We don't just break here as we may want to draw the last
            // connected line for this row even if it's off screen.
            bool isVisible = x <= rightThreshold;

            var move = x - lastX;
            canvas.translate(move, 0);
            lastX = x;

            bool isSelected;
            if (keyFrame is AllKeyFrame) {
              isSelected = _selection.containsAll(keyFrame.keyframes);
            } else {
              isSelected = _selection.contains(keyFrame);
            }

            // Draw the keyframe itself.
            if (isSelected) {
              canvas.drawPath(keyPath, _keyPaint);
              canvas.drawPath(keyPath, _selectedPaint);
            } else {
              canvas.drawPath(keyPath, keyPaint);
            }

            // Draw connecting line between keyframes.
            if (connectKeys && i != 0) {
              canvas.drawLine(
                  Offset(-move + halfBounds, halfRowHeight),
                  Offset(-halfBounds, halfRowHeight),
                  isSelected && lastSelected
                      ? _selectedPaint
                      : _connectKeyPaint);
            }

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
