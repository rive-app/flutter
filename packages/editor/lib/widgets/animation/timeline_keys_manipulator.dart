import 'dart:collection';
import 'dart:math';

import 'package:cursor/propagating_listener.dart';
import 'package:flutter/widgets.dart';
import 'package:rive_core/animation/keyed_property.dart';
import 'package:rive_core/animation/keyframe.dart';
import 'package:rive_core/animation/linear_animation.dart';
import 'package:rive_editor/rive/managers/animation/animation_time_manager.dart';
import 'package:rive_editor/rive/managers/animation/editing_animation_manager.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
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

class _TimelineKeysManipulatorState extends State<TimelineKeysManipulator> {
  HashSet<KeyFrame> _selection = HashSet<KeyFrame>();
  _DragOperation _dragOperation;
  KeyFrameMoveHelper _moveHelper;

  @override
  void initState() {
    super.initState();
    widget.activeFile.addActionHandler(_onAction);
    widget.activeFile.selection.addListener(_stageSelectionChanged);
  }

  @override
  void didUpdateWidget(TimelineKeysManipulator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeFile != widget.activeFile) {
      oldWidget.activeFile.removeActionHandler(_onAction);
      widget.activeFile.addActionHandler(_onAction);
      oldWidget.activeFile.selection.removeListener(_stageSelectionChanged);
      widget.activeFile.selection.addListener(_stageSelectionChanged);
    }
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    return PropagatingListener(
      onPointerDown: (details) {
        var selected = HashSet<KeyFrame>();

        // Gotta clean this up.
        if (widget.activeFile.rive.selectionMode.value == SelectionMode.multi) {
          selected.addAll(_selection);
        }

        var helper = makeMouseHelper();

        var frame = helper.frameAtOffset(
          details.pointerEvent.localPosition,
          widget.verticalScroll.offset,
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
          default:
            break;
        }
      },
      onPointerUp: (details) {
        _moveHelper?.complete();
        _moveHelper = null;
      },
      child: widget.builder(context, _selection),
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
