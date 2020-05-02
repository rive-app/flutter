import 'dart:collection';
import 'dart:math';

import 'package:cursor/cursor_view.dart';
import 'package:cursor/propagating_listener.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:rive_core/animation/keyed_property.dart';
import 'package:rive_core/animation/keyframe.dart';
import 'package:rive_core/animation/linear_animation.dart';
import 'package:rive_editor/rive/managers/animation/animation_time_manager.dart';
import 'package:rive_editor/rive/managers/animation/editing_animation_manager.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/widgets/animation/timeline_render_box.dart';
import 'package:rive_editor/widgets/common/cursor_icon.dart';
import 'package:rive_editor/widgets/theme.dart';
import 'package:tree_widget/flat_tree_item.dart';

enum _DragOperation {
  move,
  marquee,
  pan,
}

/// Essentially a gesture detector for manipulating the keys: selection, drag,
/// delete.
class TimelineKeysManipulator extends StatefulWidget {
  final RiveThemeData theme;
  final ScrollController verticalScroll;
  final EditingAnimationManager animationManager;
  final OpenFileContext activeFile;
  final TimelineViewport viewport;
  final List<FlatTreeItem<KeyHierarchyViewModel>> rows;

  final Widget Function(BuildContext context, HashSet<KeyFrame> selection)
      builder;

  const TimelineKeysManipulator({
    @required this.theme,
    @required this.verticalScroll,
    @required this.animationManager,
    @required this.activeFile,
    @required this.builder,
    @required this.viewport,
    @required this.rows,
    Key key,
  }) : super(key: key);

  @override
  _TimelineKeysManipulatorState createState() =>
      _TimelineKeysManipulatorState();
}

@immutable
class _Marquee {
  final double startSeconds;
  final double endSeconds;
  final double startVerticalOffset;
  final double endVerticalOffset;

  const _Marquee({
    this.startSeconds,
    this.endSeconds,
    this.startVerticalOffset,
    this.endVerticalOffset,
  });
}

class _TimelineKeysManipulatorState extends State<TimelineKeysManipulator> {
  HashSet<KeyFrame> _selection = HashSet<KeyFrame>();
  _DragOperation _dragOperation;
  KeyFrameMoveHelper _moveHelper;
  CursorInstance _handCursor;

  // Stores time & offset
  Offset _marqueeStart;
  // Stores local position so it can update during scroll/pan.
  Offset _marqueeEnd;

  // Actual marquee value.
  _Marquee _marquee;

  @override
  void initState() {
    super.initState();
    widget.verticalScroll?.addListener(_onVerticalScrollChanged);
    _onVerticalScrollChanged();
    widget.activeFile.addActionHandler(_onAction);
    widget.activeFile.selection.addListener(_stageSelectionChanged);
  }

  @override
  void didUpdateWidget(TimelineKeysManipulator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewport != widget.viewport &&
        _dragOperation == _DragOperation.marquee) {
      _updateMarquee();
    }
    if (oldWidget.verticalScroll != widget.verticalScroll) {
      oldWidget.verticalScroll?.removeListener(_onVerticalScrollChanged);
      widget.verticalScroll?.addListener(_onVerticalScrollChanged);
      _onVerticalScrollChanged();
    }
    if (oldWidget.activeFile != widget.activeFile) {
      oldWidget.activeFile.removeActionHandler(_onAction);
      widget.activeFile.addActionHandler(_onAction);
      oldWidget.activeFile.selection.removeListener(_stageSelectionChanged);
      widget.activeFile.selection.addListener(_stageSelectionChanged);
    }
  }

  void _onVerticalScrollChanged() {
    if (_dragOperation != _DragOperation.marquee) {
      return;
    }
    _updateMarquee();
  }

  @override
  void dispose() {
    widget.verticalScroll?.removeListener(_onVerticalScrollChanged);
    _handCursor?.remove();
    _handCursor = null;
    widget.activeFile.selection.removeListener(_stageSelectionChanged);
    widget.activeFile.removeActionHandler(_onAction);
    super.dispose();
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

  MouseTimelineHelper makeMouseHelper() {
    var renderBox = context.findRenderObject() as RenderBox;
    return MouseTimelineHelper(
      rows: widget.rows,
      widgetSize: renderBox.size,
      theme: widget.theme,
      viewport: widget.viewport,
    );
  }

  void _pan(Offset delta) {
    // Compute vertical scroll
    var position = widget.verticalScroll.position;
    var newPosition = min(
        max(position.pixels + delta.dy, position.minScrollExtent),
        position.maxScrollExtent);
    widget.verticalScroll.jumpTo(newPosition);

    // Compute horizontal scroll
    var helper = makeMouseHelper();
    var timeScroll = delta.dx * helper.secondsPerPixel;
    widget.animationManager.changeViewport
        .add(widget.viewport.move(timeScroll));
  }

  void _updateMarquee() {
    var viewportHelper = makeMouseHelper();
    var seconds = viewportHelper.dxToSeconds(_marqueeEnd.dx);
    var dy = _marqueeEnd.dy + widget.verticalScroll.offset;

    setState(() {
      _marquee = _Marquee(
        startSeconds: min(seconds, _marqueeStart.dx),
        endSeconds: max(seconds, _marqueeStart.dx),
        startVerticalOffset: min(dy, _marqueeStart.dy),
        endVerticalOffset: max(dy, _marqueeStart.dy),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return PropagatingListener(
      onPointerSignal: (details) {
        if (details.pointerEvent is PointerScrollEvent) {
          _pan((details.pointerEvent as PointerScrollEvent).scrollDelta);
        }
      },
      onPointerDown: (details) {
        if (details.pointerEvent.buttons == 2) {
          _handCursor = CursorIcon.show(context, 'cursor-hand');
          // right click to pan.
          _dragOperation = _DragOperation.pan;
          return;
        }

        var selected = HashSet<KeyFrame>();

        // Gotta clean this up.
        if (widget.activeFile.rive.selectionMode.value == SelectionMode.multi) {
          selected.addAll(_selection);
        }

        var helper = makeMouseHelper();

        var verticalOffset = widget.verticalScroll.offset;
        var frame = helper.frameAtOffset(
          details.pointerEvent.localPosition,
          verticalOffset,
        );
        if (frame is KeyFrame) {
          selected.add(frame);
        } else if (frame is AllKeyFrame) {
          selected.addAll(frame.keyframes);
        }
        if (selected.isNotEmpty) {
          // If we selected something, store the position we started this press
          // operation from. We'll use this in the drag (onPointerMove).
          _dragOperation = _DragOperation.move;
        } else {
          _dragOperation = _DragOperation.marquee;
          var seconds =
              helper.dxToSeconds(details.pointerEvent.localPosition.dx);
          _marqueeStart = Offset(
              seconds, details.pointerEvent.localPosition.dy + verticalOffset);
        }

        // Change the selection only if something new was selected...
        if (selected.isEmpty || !_selection.containsAll(selected)) {
          setState(() {
            _selection = selected;
          });
        }
      },
      onPointerMove: (details) {
        switch (_dragOperation) {
          case _DragOperation.pan:
            _pan(details.pointerEvent.localDelta * -1);
            break;
          case _DragOperation.move:
            if (_selection.isNotEmpty) {
              // TODO: cache viewport helpers? probably not worth it...
              var viewportHelper = makeMouseHelper();
              var seconds = viewportHelper
                  .dxToSeconds(details.pointerEvent.localPosition.dx);

              _moveHelper ??= KeyFrameMoveHelper(
                  widget.animationManager.animation,
                  _selection.toList(),
                  seconds);
              _moveHelper.dragTo(seconds);
            }
            break;
          case _DragOperation.marquee:
            _marqueeEnd = details.pointerEvent.localPosition;
            _updateMarquee();

            break;
          default:
            break;
        }
      },
      onPointerUp: (details) {
        _dragOperation = null;
        setState(() {
          _marquee = null;
        });
        _moveHelper?.complete();
        _moveHelper = null;
        _handCursor?.remove();
        _handCursor = null;
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: widget.builder(
              context,
              _selection,
            ),
          ),
          Positioned.fill(
            child: _MarqueeRenderer(
              theme: widget.theme,
              verticalScrollOffset: widget.verticalScroll.offset,
              viewport: widget.viewport,
              marquee: _marquee,
            ),
          ),
        ],
      ),
    );
  }
}

// This helper is used to track key frame origins and updating their time when
// they are moved.
class KeyFrameMoveHelper {
  final List<KeyFrame> keyFrames;
  final double fromSeconds;
  final List<int> _origins;
  final LinearAnimation animation;
  KeyFrameMoveHelper(this.animation, this.keyFrames, this.fromSeconds)
      : _origins = List(keyFrames.length) {
    // We need to store all the origins (where the keyframe started at) as when
    // we drag we need to clamp to edges and don't want to overshoot/drift when
    // the cursor clamps. That means that when the cursor hits an edge and then
    // comes back, there should be a deadzone equal to how much we moved while
    // clamped. In order to do that each drag operation must be in absolute
    // (from origin) space, or you could accumulate the clamped amount but that
    // can suffer precision and drift issues as our positions quantize to
    // integers.
    int idx = 0;
    for (final keyframe in keyFrames) {
      _origins[idx++] = keyframe.frame;
      // When we start dragging, we want to suppress validation of frame
      // positions (so we don't delete keyframes that land on the same time
      // until we capture).
      keyframe.keyedProperty.suppressValidation = true;
    }
  }

  void complete() {
    // Re-enable (and trigger) validation.
    for (final keyframe in keyFrames) {
      keyframe.keyedProperty.suppressValidation = false;
    }
    animation.context.captureJournalEntry();
  }

  void dragTo(double seconds) {
    var amount = seconds - fromSeconds;
    if (amount == 0) {
      return;
    }

    int offsetFrames = (amount * animation.fps).round();

    // First pass: clamp to edges
    int idx = 0;
    for (final keyframe in keyFrames) {
      var origin = _origins[idx++];
      var frame = origin + offsetFrames;
      if (frame < 0) {
        offsetFrames += -frame;
      }
      if (frame > animation.duration) {
        offsetFrames -= frame - animation.duration;
      }
      keyframe.frame = origin + offsetFrames;
    }
    if (offsetFrames != 0) {
      // Second pass, apply.
      int idx = 0;
      for (final keyframe in keyFrames) {
        var origin = _origins[idx++];
        keyframe.frame = origin + offsetFrames;
      }
    }
  }
}

class MouseTimelineViewportHelper {
  double _secondsPerPixel;
  double get secondsPerPixel => _secondsPerPixel;
  final double _marginLeft;
  double get marginLeft => _marginLeft;
  final TimelineViewport viewport;

  MouseTimelineViewportHelper(
    Size widgetSize,
    RiveThemeData theme,
    this.viewport,
  ) : _marginLeft = theme.dimensions.timelineMarginLeft {
    var marginRight = theme.dimensions.timelineMarginRight;

    var visibleDuration = viewport.endSeconds - viewport.startSeconds;
    _secondsPerPixel =
        visibleDuration / (widgetSize.width - _marginLeft - marginRight);
  }

  double dxToSeconds(double dx) =>
      viewport.startSeconds + (-_marginLeft + dx) * secondsPerPixel;
}

class MouseTimelineHelper extends MouseTimelineViewportHelper {
  // Row height in pixels.
  final double _rowHeight;

  // How far we can be from the key in frame space to consider it
  // selected/clicked.
  double _horizontalThreshold;

  final List<FlatTreeItem<KeyHierarchyViewModel>> rows;
  MouseTimelineHelper({
    Size widgetSize,
    RiveThemeData theme,
    TimelineViewport viewport,
    this.rows,
  })  : _rowHeight = theme.treeStyles.timeline.itemHeight,
        super(widgetSize, theme, viewport) {
    _horizontalThreshold =
        theme.dimensions.keyHalfBounds * secondsPerPixel * viewport.fps;
  }

  /// Returns the KeyFrame that was clicked on.
  KeyFrameInterface frameAtOffset(
    Offset position,
    double verticalScroll,
  ) {
    // First find closest row.
    var rowIndex = ((verticalScroll + position.dy) / _rowHeight).floor();
    var row = rows[rowIndex].data;

    // Closest seconds to where we clicked.
    var searchSeconds = dxToSeconds(position.dx);

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
    for (var i = start; i < end; i++) {
      var diff = (frames[i].frame - firstFrameDouble).abs();
      if (diff <= _horizontalThreshold && diff < closest) {
        hit = frames[i];
      }
    }

    return hit;
  }
}

class _MarqueeRenderer extends LeafRenderObjectWidget {
  final RiveThemeData theme;
  final double verticalScrollOffset;
  final _Marquee marquee;
  final TimelineViewport viewport;

  const _MarqueeRenderer({
    @required this.theme,
    @required this.verticalScrollOffset,
    @required this.viewport,
    @required this.marquee,
  });
  @override
  RenderObject createRenderObject(BuildContext context) {
    return _MarqueeRenderObject()
      ..theme = theme
      ..verticalScrollOffset = verticalScrollOffset
      ..viewport = viewport
      ..marquee = marquee;
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant _MarqueeRenderObject renderObject) {
    renderObject
      ..theme = theme
      ..verticalScrollOffset = verticalScrollOffset
      ..viewport = viewport
      ..marquee = marquee;
  }
}

class _MarqueeRenderObject extends TimelineRenderBox {
  final Paint _stroke = Paint()
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke;
  final Paint _fill = Paint();

  // We compute our own range as the one given by the viewport is padded, we
  // actually need to draw a little more than the viewport.
  double _secondsStart = 0;

  double _verticalScrollOffset;
  double get verticalScrollOffset => _verticalScrollOffset;
  set verticalScrollOffset(double value) {
    if (_verticalScrollOffset == value) {
      return;
    }
    _verticalScrollOffset = value;
    markNeedsPaint();
  }

  _Marquee _marquee;
  _Marquee get marquee => _marquee;
  set marquee(_Marquee value) {
    if (value == _marquee) {
      return;
    }
    _marquee = value;
    markNeedsPaint();
  }

  @override
  void onThemeChanged(RiveThemeData theme) {
    _stroke.color = theme.colors.keyMarqueeStroke;
    _fill.color = theme.colors.keyMarqueeFill;
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

    var rect = Rect.fromLTRB(
      ((marquee.startSeconds - _secondsStart) / secondsPerPixel)
              .roundToDouble() -
          0.5,
      (marquee.startVerticalOffset - _verticalScrollOffset).roundToDouble() -
          0.5,
      ((marquee.endSeconds - _secondsStart) / secondsPerPixel).roundToDouble() +
          0.5,
      (marquee.endVerticalOffset - _verticalScrollOffset).roundToDouble() + 0.5,
    );
    canvas.drawRect(rect, _fill);
    canvas.drawRect(rect, _stroke);
    canvas.restore();
  }
}
