import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:cursor/cursor_view.dart';
import 'package:cursor/propagating_listener.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:rive_core/animation/keyed_property.dart';
import 'package:rive_core/animation/keyframe.dart';
import 'package:rive_core/animation/linear_animation.dart';
import 'package:rive_editor/constants.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/rive/managers/animation/animation_time_manager.dart';
import 'package:rive_editor/rive/managers/animation/editing_animation_manager.dart';
import 'package:rive_editor/rive/managers/animation/keyframe_manager.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/widgets/animation/timeline_render_box.dart';
import 'package:rive_editor/widgets/common/cursor_icon.dart';
import 'package:rive_editor/widgets/theme.dart';
import 'package:tree_widget/flat_tree_item.dart';

/// Different kinds of mouse drag operations this manipulator supports.
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
  final KeyFrameManager keyFrameManager;
  final OpenFileContext activeFile;
  final TimelineViewport viewport;
  final List<FlatTreeItem<KeyHierarchyViewModel>> rows;

  final WidgetBuilder builder;
  final HashSet<KeyHierarchyViewModel> expandedRows;

  const TimelineKeysManipulator({
    @required this.theme,
    @required this.verticalScroll,
    @required this.animationManager,
    @required this.keyFrameManager,
    @required this.activeFile,
    @required this.builder,
    @required this.viewport,
    @required this.rows,
    @required this.expandedRows,
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
  _DragOperation _dragOperation;
  KeyFrameMoveHelper _moveHelper;
  CursorInstance _handCursor;
  bool _didDrag = false;

  // Stores time & offset
  Offset _marqueeStart;
  // Stores local position so it can update during scroll/pan.
  Offset _marqueeEnd;
  HashSet<KeyFrame> _preSelected;
  HashSet<KeyFrame> _downHit;

  // Actual marquee value.
  _Marquee _marquee;

  Offset _edgeScroll;
  Timer _edgeScrollTimer;
  DateTime _lastHitTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    ShortcutAction.multiSelect.addListener(_updateMarquee);
    widget.verticalScroll?.addListener(_onVerticalScrollChanged);
    _onVerticalScrollChanged();
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
  }

  void _onVerticalScrollChanged() {
    if (_dragOperation != _DragOperation.marquee) {
      return;
    }
    _updateMarquee();
  }

  @override
  void dispose() {
    ShortcutAction.multiSelect.removeListener(_updateMarquee);
    _edgeScrollTimer?.cancel();
    widget.verticalScroll?.removeListener(_onVerticalScrollChanged);
    _handCursor?.remove();
    _handCursor = null;
    super.dispose();
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

  void _bumpEdgeScroll(Timer timer) {
    _pan(_edgeScroll);
  }

  void _updateMarquee() {
    if (_marqueeStart == null || _marqueeEnd == null) {
      return;
    }
    var viewportHelper = makeMouseHelper();
    var seconds = viewportHelper.dxToSeconds(_marqueeEnd.dx);
    var dy = _marqueeEnd.dy + widget.verticalScroll.offset;

    var marquee = _Marquee(
      startSeconds: min(seconds, _marqueeStart.dx),
      endSeconds: max(seconds, _marqueeStart.dx),
      startVerticalOffset: min(dy, _marqueeStart.dy),
      endVerticalOffset: max(dy, _marqueeStart.dy),
    );

    // Compute selected items.
    var toSelect = viewportHelper.framesIn(marquee, widget.expandedRows);

    var preSelect = _downHit.isEmpty && !ShortcutAction.multiSelect.value
        ? HashSet<KeyFrame>()
        : _preSelected;
    var fullSelection = HashSet<KeyFrame>.of(preSelect);
    fullSelection.addAll(toSelect);

    if (ShortcutAction.multiSelect.value) {
      // When multi-selecting, remove intersection from the set.
      fullSelection.removeAll(preSelect.intersection(toSelect));
    }
    widget.keyFrameManager.changeSelection.add(fullSelection);

    setState(() {
      _marquee = marquee;
    });

    // Update edge scroll

    var edgeScroll = Offset.zero;
    const double edgeBumpAmount = 12;
    const int edgeBumpMs = 35;
    if (_marqueeEnd.dy < 0) {
      edgeScroll = Offset(edgeScroll.dx, -edgeBumpAmount);
    } else if (_marqueeEnd.dy > viewportHelper.widgetSize.height) {
      edgeScroll = Offset(edgeScroll.dx, edgeBumpAmount);
    }
    if (_marqueeEnd.dx < 0) {
      edgeScroll = Offset(-edgeBumpAmount, edgeScroll.dy);
    } else if (_marqueeEnd.dx > viewportHelper.widgetSize.width) {
      edgeScroll = Offset(edgeBumpAmount, edgeScroll.dy);
    }
    if (edgeScroll != Offset.zero) {
      _edgeScroll = edgeScroll;
      _edgeScrollTimer ??= Timer.periodic(
          const Duration(milliseconds: edgeBumpMs), _bumpEdgeScroll);
    } else {
      _edgeScrollTimer?.cancel();
      _edgeScrollTimer = null;
    }
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
        _didDrag = false;
        if (details.pointerEvent.buttons == 2) {
          _handCursor = CursorIcon.show(context, PackedIcon.cursorHand);
          // right click to pan.
          _dragOperation = _DragOperation.pan;
          return;
        }

        _preSelected =
            HashSet<KeyFrame>.from(widget.keyFrameManager.selection.value);

        var toSelect = HashSet<KeyFrame>();

        var helper = makeMouseHelper();

        var verticalOffset = widget.verticalScroll.offset;
        var frame = helper.frameAtOffset(
          details.pointerEvent.localPosition,
          verticalOffset,
          widget.expandedRows,
        );
        if (frame is KeyFrame) {
          toSelect.add(frame);
        } else if (frame is AllKeyFrame) {
          toSelect.addAll(frame.keyframes);
        }

        // Track the last time we clicked.
        var now = DateTime.now();
        if ((now.difference(_lastHitTime)) < doubleClickSpeed) {
          // Move the playhead to the double clicked time.
          var manager = widget.animationManager;

          // if we hit something, move to the time of that keyframe.
          if (toSelect.isNotEmpty) {
            manager.changeCurrentTime
                .add(toSelect.first.frame / manager.animation.fps);
          } else {
            // otherwise go to the closest frame time.
            manager.changeCurrentTime
                .add(helper.dxToSeconds(details.pointerEvent.localPosition.dx));
          }
        }
        _lastHitTime = now;

        if (toSelect.isNotEmpty) {
          // If we selected something, store the position we started this press
          // operation from. We'll use this in the drag (onPointerMove).
          _dragOperation = _DragOperation.move;
        } else {
          _dragOperation = _DragOperation.marquee;
          widget.keyFrameManager.isSelecting.add(true);
          var seconds =
              helper.dxToSeconds(details.pointerEvent.localPosition.dx);
          _marqueeStart = Offset(
              seconds, details.pointerEvent.localPosition.dy + verticalOffset);
        }

        var fullSelection = HashSet<KeyFrame>.of(_preSelected);
        fullSelection.addAll(toSelect);
        _downHit = toSelect;

        bool isReselect = _preSelected.containsAll(toSelect);

        if (ShortcutAction.multiSelect.value && isReselect) {
          // We're holding multiselect and we're clicking on something already
          // selected, so remove the already selected set from the selection
          // (toggle it off).
          fullSelection.removeAll(toSelect);
        } else if (!ShortcutAction.multiSelect.value && !isReselect) {
          // We're not holding multiselect and this is a new selection, so we
          // want the selection to only be the new stuff we selected. Remove the
          // preselect.
          fullSelection.removeAll(_preSelected);
        } else if (_downHit.isEmpty) {
          fullSelection.clear();
        }

        widget.keyFrameManager.changeSelection.add(fullSelection);
      },
      onPointerMove: (details) {
        _didDrag = true;
        switch (_dragOperation) {
          case _DragOperation.pan:
            _pan(details.pointerEvent.localDelta * -1);
            break;
          case _DragOperation.move:
            var currentSelection = widget.keyFrameManager.selection.value;
            if (currentSelection.isNotEmpty) {
              // TODO: cache viewport helpers? probably not worth it...
              var viewportHelper = makeMouseHelper();
              var seconds = viewportHelper
                  .dxToSeconds(details.pointerEvent.localPosition.dx);

              _moveHelper ??= KeyFrameMoveHelper(
                  widget.animationManager.animation,
                  List<KeyFrame>.from(currentSelection, growable: false),
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
        if (!_didDrag && !ShortcutAction.multiSelect.value) {
          // We didn't drag and we're not multi selecting so change the
          // selection to what was hit on down.
          widget.keyFrameManager.changeSelection.add(_downHit);
        }
        widget.keyFrameManager.isSelecting.add(false);
        _edgeScrollTimer?.cancel();
        _edgeScrollTimer = null;
        _dragOperation = null;
        _marqueeStart = _marqueeEnd = null;
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
            child: widget.builder(context),
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
    // The manipulator should know that your priority was the selected
    // keyframes, so it should do a manual validation prioritizing keys that
    // were dragged.
    var keyframesSet = HashSet<KeyFrame>.from(keyFrames);

    var context = animation.context;

    for (final keyframe in keyframesSet) {
      var keyedProperty = keyframe.keyedProperty;
      var keyedPropertyFrames = keyedProperty.keyframes.toList(growable: false);
      for (final frame in keyedPropertyFrames) {
        if (keyframesSet.contains(frame)) {
          continue;
        }
        if (frame.frame == keyframe.frame) {
          // This frame collides with keyframe, remove it (prioritizes our
          // dragged keyframe).
          context.removeObject(frame);
        }
      }
    }

    // Re-enable (and trigger) regular validation.
    for (final keyframe in keyFrames) {
      keyframe.keyedProperty.suppressValidation = false;
    }
    context.captureJournalEntry();
  }

  void dragTo(double seconds) {
    var amount = seconds - fromSeconds;
    if (amount == 0) {
      return;
    }

    int offsetFrames = (amount * animation.fps).round();

    // First pass: clamp offset to edges, do not apply
    for (int i = 0; i < _origins.length; i++) {
      var origin = _origins[i];
      var frame = origin + offsetFrames;
      if (frame < 0) {
        offsetFrames += -frame;
      }
      if (frame > animation.duration) {
        offsetFrames -= frame - animation.duration;
      }
    }
    // Second pass, apply.
    int idx = 0;
    for (final keyframe in keyFrames) {
      var origin = _origins[idx++];
      keyframe.frame = origin + offsetFrames;
    }
  }
}

/// Class to help convert between viewport space, screenspace, and row space.
class MouseTimelineViewportHelper {
  double _secondsPerPixel;
  double get secondsPerPixel => _secondsPerPixel;
  final double _marginLeft;
  double get marginLeft => _marginLeft;
  final TimelineViewport viewport;
  final Size widgetSize;
  MouseTimelineViewportHelper(
    this.widgetSize,
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
  final double _keyHitRadius;

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
        _keyHitRadius = theme.dimensions.keySize / 2 + 1,
        super(widgetSize, theme, viewport) {
    _horizontalThreshold =
        theme.dimensions.keyUpper * secondsPerPixel * viewport.fps;
  }

  HashSet<KeyFrame> framesIn(
      _Marquee marquee, HashSet<KeyHierarchyViewModel> expandedRows) {
    HashSet<KeyFrame> keyframes = HashSet<KeyFrame>();

    // First find closest rows.
    var rowIndexFrom = ((marquee.startVerticalOffset) / _rowHeight)
        .round()
        .clamp(0, rows.length)
        .toInt();
    var rowIndexTo = ((marquee.endVerticalOffset) / _rowHeight)
        .round()
        .clamp(0, rows.length)
        .toInt();
    // var row = rows[rowIndex].data;

    var fps = viewport.fps;

    for (int i = rowIndexFrom; i < rowIndexTo; i++) {
      var row = rows[i].data;

      KeyFrameList keyFrameList;
      if (row is KeyedPropertyViewModel) {
        keyFrameList = row.keyedProperty;
      } else if (row is AllKeysViewModel) {
        if (expandedRows.contains(row)) {
          // Row is expanded, all key is hidden and unselectable.
          continue;
        }
        keyFrameList = row.allProperties.cached;
      }
      List<KeyFrameInterface> frames =
          keyFrameList.keyframes as List<KeyFrameInterface>;

      double firstFrameDouble = marquee.startSeconds * fps;
      double lastFrameDouble = marquee.endSeconds * fps;

      var frameIndexFrom = keyFrameList.indexOfFrame(firstFrameDouble.floor());
      var frameIndexTo = min(frames.length - 1,
          keyFrameList.indexOfFrame(lastFrameDouble.floor()));

      for (int j = frameIndexFrom; j <= frameIndexTo; j++) {
        var keyframe = frames[j];
        if (keyframe.frame < firstFrameDouble ||
            keyframe.frame > lastFrameDouble) {
          continue;
        }
        if (keyframe is AllKeyFrame) {
          keyframes.addAll(keyframe.keyframes);
        } else if (keyframe is KeyFrame) {
          keyframes.add(keyframe);
        }
      }
    }

    return keyframes;
  }

  /// Returns the KeyFrame that was clicked on.
  KeyFrameInterface frameAtOffset(
    Offset position,
    double verticalScroll,
    HashSet<KeyHierarchyViewModel> expandedRows,
  ) {
    // First find closest row.
    var realRowIndex = (verticalScroll + position.dy) / _rowHeight;
    var rowIndex = realRowIndex.floor();
    if (rowIndex < 0 || rowIndex >= rows.length) {
      return null;
    }
    var distanceFromCenter =
        (0.5 - (realRowIndex - rowIndex)).abs() * _rowHeight;
    if (distanceFromCenter > _keyHitRadius) {
      return null;
    }

    var row = rows[rowIndex].data;

    // Closest seconds to where we clicked.
    var searchSeconds = dxToSeconds(position.dx);

    KeyFrameList keyFrameList;
    if (row is KeyedPropertyViewModel) {
      keyFrameList = row.keyedProperty;
    } else if (row is AllKeysViewModel) {
      if (expandedRows.contains(row)) {
        // Row is expanded, all key is hidden and unselectable.
        return null;
      }
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

/// Draws the marquee.
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
