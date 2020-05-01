import 'dart:collection';
import 'dart:math';

import 'package:cursor/propagating_listener.dart';
import 'package:flutter/widgets.dart';
import 'package:rive_core/animation/keyed_property.dart';
import 'package:rive_core/animation/keyframe.dart';
import 'package:rive_core/animation/linear_animation.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_editor/rive/managers/animation/animation_time_manager.dart';
import 'package:rive_editor/rive/managers/animation/editing_animation_manager.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/widgets/animation/keyed_object_tree_controller.dart';
import 'package:rive_editor/widgets/animation/timeline_render_box.dart';
import 'package:rive_editor/widgets/common/value_stream_builder.dart';
import 'package:rive_editor/widgets/theme.dart';
import 'package:tree_widget/flat_tree_item.dart';

const double _keyRadius = 4;
// const double _keySquare = _keyRadius * 2;
const double _visualKeyRadius =
    5.6568542495; // //sqrt(_keySquare + _keySquare) / 2;

/// Draws the rows in the timeline, separators, and their respective keys. Also
/// handles interaction/user input with them.
class TimelineKeys extends StatefulWidget {
  final RiveThemeData theme;
  final ScrollController verticalScroll;
  final KeyedObjectTreeController treeController;
  final EditingAnimationManager animationManager;
  final OpenFileContext activeFile;

  const TimelineKeys({
    @required this.theme,
    @required this.verticalScroll,
    @required this.treeController,
    @required this.animationManager,
    @required this.activeFile,
    Key key,
  }) : super(key: key);

  @override
  _TimelineKeysState createState() => _TimelineKeysState();
}

class _TimelineKeysState extends State<TimelineKeys> {
  double _scrollOffset = 0;
  List<FlatTreeItem<KeyHierarchyViewModel>> _rows = [];
  HashSet<KeyFrame> _selection = HashSet<KeyFrame>();

  @override
  void initState() {
    super.initState();
    widget.activeFile.addActionHandler(_onAction);
    widget.activeFile.selection.addListener(_stageSelectionChanged);
    widget.verticalScroll?.addListener(_onVerticalScrollChanged);
    _onVerticalScrollChanged();
    widget.treeController?.addListener(_onFlatListChanged);
    _onFlatListChanged();
  }

  void _clearSelection() {
    setState(() {
      _selection = HashSet<KeyFrame>();
    });
  }

  void _stageSelectionChanged() {
    _clearSelection();
  }

  bool _onAction(ShortcutAction action) {
    switch (action) {
      case ShortcutAction.delete:
        if (_selection.isNotEmpty) {
          widget.animationManager.deleteKeyFrames.add(_selection);
          _clearSelection();
          return true;
        }
        break;
    }
    return false;
  }

  @override
  void didUpdateWidget(TimelineKeys oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeFile != widget.activeFile) {
      oldWidget.activeFile.removeActionHandler(_onAction);
      widget.activeFile.addActionHandler(_onAction);
      oldWidget.activeFile.selection.removeListener(_stageSelectionChanged);
      widget.activeFile.selection.addListener(_stageSelectionChanged);
    }
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
    widget.activeFile.selection.removeListener(_stageSelectionChanged);
    widget.activeFile.removeActionHandler(_onAction);
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
        return PropagatingListener(
          onPointerDown: (details) {
            var renderBox = context.findRenderObject() as RenderBox;

            var selected = HashSet<KeyFrame>();

            // Gotta clean this up.
            if (widget.activeFile.rive.selectionMode.value ==
                SelectionMode.multi) {
              selected.addAll(_selection);
            }
            var frame = KeyFrameCursorHelper.click(
                details.pointerEvent.localPosition,
                renderBox.size,
                widget.theme,
                viewport,
                _scrollOffset,
                _rows);
            if (frame is KeyFrame) {
              selected.add(frame);
            } else if (frame is AllKeyFrame) {
              selected.addAll(frame.keyframes);
            }
            setState(() {
              _selection = selected;
            });
          },
          child: _TimelineKeysRenderer(
            theme: widget.theme,
            verticalScrollOffset: _scrollOffset,
            rows: _rows,
            viewport: viewport,
            animation: widget.animationManager.animation,
            selection: _selection,
          ),
        );
      },
    );
  }
}

class KeyFrameCursorHelper {
  /// Returns the KeyFrame that was clicked on.
  static KeyFrameInterface click(
      Offset position,
      Size size,
      RiveThemeData theme,
      TimelineViewport viewport,
      double verticalScroll,
      List<FlatTreeItem<KeyHierarchyViewModel>> rows) {
    // First find closest row.
    var rowHeight = theme.treeStyles.timeline.itemHeight;

    var rowIndex = ((verticalScroll + position.dy) / rowHeight).floor();
    var row = rows[rowIndex].data;

    var marginLeft = theme.dimensions.timelineMarginLeft;
    var marginRight = theme.dimensions.timelineMarginRight;

    var visibleDuration = viewport.endSeconds - viewport.startSeconds;
    var secondsPerPixel =
        visibleDuration / (size.width - marginLeft - marginRight);
        
    // Closest seconds to where we clicked.
    var searchSeconds =
        viewport.startSeconds + (-marginLeft + position.dx) * secondsPerPixel;

    KeyFrameList keyFrameList;
    if (row is KeyedPropertyViewModel) {
      keyFrameList = row.keyedProperty;
    } else if (row is AllKeysViewModel) {
      keyFrameList = row.allProperties.cached;
    }

    if (keyFrameList == null) {
      return null;
    }

    var fps = viewport.fps;
    List<KeyFrameInterface> frames =
        keyFrameList.keyframes as List<KeyFrameInterface>;
    
    // Find the time in frames but store it as a double so we can do precise
    // distance evaluation below. We
    double firstFrameDouble = searchSeconds * fps;
    var firstFrame = firstFrameDouble.floor();
    var index = keyFrameList.indexOfFrame(firstFrame);

    // When we click, we want to get close with our binary search and then check
    // the three nearest neighbors for which one we're closest to.
    var start = max(index - 1, 0);
    var end = min(index + 2, frames.length);
    double closest = double.maxFinite;
    KeyFrameInterface hit;

    // We compare in frame (fps) space so we need to convert pixels to frames.
    var threshold = _visualKeyRadius * secondsPerPixel * fps;
    for (var i = start; i < end; i++) {
      var diff = (frames[i].frame - firstFrameDouble).abs();
      if (diff <= threshold && diff < closest) {
        hit = frames[i];
      }
    }

    return hit;
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

class _TimelineKeysRenderObject extends TimelineRenderBox {
  final Paint _bgPaint = Paint();
  final Paint _separatorPaint = Paint();
  final Paint _keyPaint = Paint();
  final Paint _allkeyPaint = Paint();
  final Paint _selectedPaint = Paint()
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke;
  final Path _keyPath = Path();

  // We compute our own range as the one given by the viewport is padded, we
  // actually need to draw a little more than the viewport.
  double _secondsStart = 0;
  double _secondsEnd = 0;

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
    _allkeyPaint.color = theme.colors.allKey;
    _selectedPaint.color = theme.colors.keySelection;

    var transform = Mat2D();
    Mat2D.fromRotation(transform, pi / 4);
    _keyPath.reset();
    _keyPath.addPath(
      Path()
        ..addRect(const Rect.fromLTRB(
            -_keyRadius, -_keyRadius, _keyRadius, _keyRadius)),
      Offset(0, theme.treeStyles.timeline.itemHeight / 2),
      matrix4: transform.mat4,
    );
    markNeedsLayout();
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
    var marginRight = theme.dimensions.timelineMarginRight;

    // This is the time at local x 0
    _secondsStart = viewport.startSeconds - marginLeft * secondsPerPixel;
    // This is the time at local x width
    _secondsEnd = viewport.endSeconds + marginRight * secondsPerPixel;
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
    var rightThreshold = size.width + _keyRadius;

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
      if (row is KeyedPropertyViewModel) {
        keyFrameList = row.keyedProperty;
        keyPaint = _keyPaint;
      } else if (row is AllKeysViewModel) {
        keyFrameList = row.allProperties.cached;
        keyPaint = _allkeyPaint;
      }

      if (keyFrameList != null) {
        List<KeyFrameInterface> frames =
            keyFrameList.keyframes as List<KeyFrameInterface>;
        // inxedOfFrame does a binary search on integer frame values so we need
        // to offset the first frame by one to compensate for rounding errors.
        // We end up potentially drawing an extra frame, but the it fixes
        // popping and still culls majority of out of viewport frames.
        var firstFrame = (_secondsStart * viewport.fps).floor() - 1;
        var index = keyFrameList.indexOfFrame(firstFrame);
        int frameCount = frames.length;
        var fps = viewport.fps;
        double lastX = 0;
        if (index < frameCount) {
          lastX = (frames[index].frame / fps - _secondsStart) / secondsPerPixel;
          canvas.translate(lastX, 0);
          for (int i = index; i < frameCount; i++) {
            var keyFrame = frames[i];
            var x = (keyFrame.frame / fps - _secondsStart) / secondsPerPixel;

            if (x > rightThreshold) {
              // This row is done, it fell off the edge...
              break;
            }
            canvas.translate(x - lastX, 0);
            lastX = x;

            bool isSelected;
            if (keyFrame is AllKeyFrame) {
              isSelected = _selection.containsAll(keyFrame.keyframes);
            } else {
              isSelected = _selection.contains(keyFrame);
            }
            if (isSelected) {
              canvas.drawPath(_keyPath, _keyPaint);
              canvas.drawPath(_keyPath, _selectedPaint);
            } else {
              canvas.drawPath(_keyPath, keyPaint);
            }
          }
        }
        canvas.translate(-lastX, 0);
      }

      canvas.translate(0, rowHeight);
    }

    canvas.restore();
  }
}
