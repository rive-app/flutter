import 'package:flutter/widgets.dart';
import 'package:rive_editor/rive/managers/animation/animation_time_manager.dart';
import 'package:rive_editor/rive/managers/animation/editing_animation_manager.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:rive_editor/widgets/common/overlay_hit_detect.dart';
import 'package:rive_editor/widgets/common/value_stream_builder.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/theme.dart';

/// Viewport controls that allow scrubbing and zooming the timeline.
class TimelineViewportControls extends StatelessWidget {
  static const double grabberHitSize = 10;
  static const double grabberSize = 10;
  static const double grabberRadius = grabberSize / 2;
  static const double height = 10;

  /// Draw the same background for the controls even if we don't have a
  /// currently editing animation.
  Widget _buildEmpty(BuildContext context) {
    return SizedBox(
      height: height,
      child: _TimelineViewportControlsRenderer(
        null,
        RiveTheme.of(context).colors,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: ActiveFile.of(context).editingAnimationManager,
      builder: (context, EditingAnimationManager editingAnimation, _) {
        if (editingAnimation == null) {
          return _buildEmpty(context);
        }
        return ValueStreamBuilder<TimelineViewport>(
          stream: editingAnimation.viewport,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return _buildEmpty(context);
            }
            var viewport = snapshot.data;
            return SizedBox(
              height: height,
              child: CustomMultiChildLayout(
                delegate: _ViewportControlsLayoutDelegate(viewport),
                children: [
                  LayoutId(
                    id: _ViewportControlPart.renderer,
                    child: _TimelineViewportControlsRenderer(
                      viewport,
                      RiveTheme.of(context).colors,
                    ),
                  ),
                  LayoutId(
                    id: _ViewportControlPart.track,
                    child: DragListener<TimelineViewport>(
                      startValue: viewport,
                      dragContext: context,
                      child: const SizedBox(),
                      onDrag: (startViewport, startOffset, toOffset, size) {
                        editingAnimation.changeViewport.add(startViewport.move(
                            (toOffset.dx - startOffset.dx) /
                                size.width *
                                startViewport.totalSeconds));
                      },
                    ),
                  ),
                  LayoutId(
                    id: _ViewportControlPart.left,
                    child: OverlayHitDetect(
                      customCursorIcon: 'cursor-resize-horizontal',
                      dragContext: context,
                      child: const SizedBox(
                        width: grabberHitSize,
                        height: grabberHitSize,
                      ),
                      drag: (_, normalized) {
                        editingAnimation.changeViewport.add(viewport
                            .moveStart(normalized.dx * viewport.totalSeconds));
                      },
                    ),
                  ),
                  LayoutId(
                    id: _ViewportControlPart.right,
                    child: OverlayHitDetect(
                      customCursorIcon: 'cursor-resize-horizontal',
                      dragContext: context,
                      child: const SizedBox(
                          width: grabberHitSize, height: grabberHitSize),
                      drag: (_, normalized) {
                        editingAnimation.changeViewport.add(viewport
                            .moveEnd(normalized.dx * viewport.totalSeconds));
                      },
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}

enum _ViewportControlPart { left, track, right, renderer }

/// This lays out the various helpers that we use for hit detection to
/// manipulate the viewport. None of these actually render content (apart from
/// the Renderer which this also places).
class _ViewportControlsLayoutDelegate extends MultiChildLayoutDelegate {
  final TimelineViewport viewport;

  _ViewportControlsLayoutDelegate(this.viewport);
  @override
  void performLayout(Size size) {
    var width = size.width - TimelineViewportControls.grabberSize;
    var widthRatio =
        (viewport.endSeconds - viewport.startSeconds) / viewport.totalSeconds;
    layoutChild(
      _ViewportControlPart.left,
      const BoxConstraints(),
    );
    layoutChild(
      _ViewportControlPart.right,
      const BoxConstraints(),
    );
    layoutChild(
      _ViewportControlPart.track,
      BoxConstraints.tightFor(
        height: size.height,
        width: width * widthRatio,
      ),
    );

    layoutChild(
      _ViewportControlPart.renderer,
      BoxConstraints.tightFor(
        height: size.height,
        width: size.width,
      ),
    );
    positionChild(
      _ViewportControlPart.renderer,
      Offset.zero,
    );
    positionChild(
      _ViewportControlPart.track,
      Offset(
        TimelineViewportControls.grabberRadius +
            viewport.startSeconds / viewport.totalSeconds * width,
        0,
      ),
    );
    double verticalShift = TimelineViewportControls.grabberRadius -
        TimelineViewportControls.grabberHitSize / 2;
    double horizontalShift = TimelineViewportControls.grabberRadius / 2 -
        TimelineViewportControls.grabberHitSize / 2;
    positionChild(
      _ViewportControlPart.left,
      Offset(
        viewport.startSeconds / viewport.totalSeconds * width + horizontalShift,
        verticalShift,
      ),
    );
    positionChild(
      _ViewportControlPart.right,
      Offset(
        TimelineViewportControls.grabberRadius +
            viewport.endSeconds / viewport.totalSeconds * width +
            horizontalShift,
        verticalShift,
      ),
    );
  }

  @override
  bool shouldRelayout(_ViewportControlsLayoutDelegate oldDelegate) =>
      oldDelegate.viewport != viewport;
}

class _TimelineViewportControlsRenderer extends LeafRenderObjectWidget {
  final TimelineViewport viewport;
  final RiveColors colors;

  const _TimelineViewportControlsRenderer(
    this.viewport,
    this.colors,
  );

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _TimelineViewportControlsRenderObject()
      ..viewport = viewport
      ..colors = colors;
  }

  @override
  void updateRenderObject(BuildContext context,
      covariant _TimelineViewportControlsRenderObject renderObject) {
    renderObject
      ..viewport = viewport
      ..colors = colors;
  }

  @override
  void didUnmountRenderObject(
      covariant _TimelineViewportControlsRenderObject renderObject) {
    // Any cleanup to do here?
  }
}

class _TimelineViewportControlsRenderObject extends RenderBox {
  TimelineViewport _viewport;
  RiveColors _colors;

  Paint _background;
  Paint _grabber;
  Paint _track;

  RiveColors get colors => _colors;
  set colors(RiveColors value) {
    if (value == _colors) {
      return;
    }
    _colors = value;
    _background = Paint()..color = value.timelineViewportControlsBackground;
    _grabber = Paint()..color = value.timelineViewportControlsGrabber;
    _track = Paint()..color = value.timelineViewportControlsTrack;
    markNeedsPaint();
  }

  TimelineViewport get viewport => _viewport;
  set viewport(TimelineViewport value) {
    if (_viewport == value) {
      return;
    }
    _viewport = value;
    markNeedsPaint();
  }

  @override
  bool get sizedByParent => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_background == null) {
      return;
    }
    var canvas = context.canvas;

    // draw background
    canvas.drawRRect(
        RRect.fromRectAndRadius(offset & size, const Radius.circular(15)),
        _background);

    if (viewport != null) {
      const double radius = TimelineViewportControls.grabberRadius;
      var width = size.width - TimelineViewportControls.grabberSize;
      var widthRatio =
          (viewport.endSeconds - viewport.startSeconds) / viewport.totalSeconds;

      var left = viewport.startSeconds / viewport.totalSeconds * width;
      var right = viewport.endSeconds / viewport.totalSeconds * width;

      canvas.drawCircle(
          offset + Offset(radius + left, radius), radius, _grabber);

      canvas.drawCircle(
          offset + Offset(radius + right, radius), radius, _grabber);

      canvas.drawRect(
          offset + Offset(radius + left, 0) &
              Size(width * widthRatio, size.height),
          _track);
    }
  }
}

/// A drag listener that helps track initial drag values making it easier to
/// clamp at edges without having to rely only on delta which can cause weird
/// cursor shift when clamping. This might be a repeatable pattern that can be
/// generalized into a common widget.
class DragListener<T> extends StatefulWidget {
  final T startValue;
  final Widget child;
  final void Function(T, Offset, Offset, Size) onDrag;
  final BuildContext dragContext;
  const DragListener({
    this.child,
    this.onDrag,
    this.dragContext,
    this.startValue,
  });

  @override
  _DragListenerState<T> createState() => _DragListenerState<T>();
}

class _DragListenerState<T> extends State<DragListener<T>> {
  Rive _dragOperationOn;

  Offset _startDragFrom;
  T _dragStart;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (details) {
        _dragStart = widget.startValue;
        _startDragFrom = details.position;
        (_dragOperationOn = RiveContext.find(context)).startDragOperation();
      },
      onPointerMove: (details) {
        RenderBox renderBox =
            (widget.dragContext ?? context).findRenderObject() as RenderBox;
        final size = renderBox.size;

        widget.onDrag?.call(_dragStart, _startDragFrom, details.position, size);
      },
      onPointerUp: (details) {
        _dragOperationOn?.endDragOperation();
      },
      child: widget.child,
    );
  }
}
