import 'dart:collection';
import 'dart:ui';

import 'package:cursor/propagating_listener.dart';
import 'package:flutter/widgets.dart';
import 'package:rive_core/math/circle_constant.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/rive/managers/animation/animation_time_manager.dart';
import 'package:rive_editor/rive/managers/animation/editing_animation_manager.dart';
import 'package:rive_editor/widgets/animation/timeline_render_box.dart';
import 'package:rive_editor/widgets/common/overlay_hit_detect.dart';
import 'package:rive_editor/widgets/common/value_stream_builder.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/theme.dart';

/// A guide view on the top of the timeline that shows the current viewport
/// range, makes it easy to line up keyframes. Works based off the current
/// viewport and ticks are aligned to frame rate.
class TimelineTicks extends StatelessWidget {
  static const double height = 19;
  static const double workAreaGrabberWidth = 10;
  static const double workAreaGrabberHeight = 10;

  /// Draw the same background for the controls even if we don't have a
  /// currently editing animation.
  Widget _buildEmpty(BuildContext context) {
    return SizedBox(
      height: height,
      child: _TimelineTicksRenderer(
        null,
        RiveTheme.of(context),
        const WorkAreaViewModel(start: 0, end: 0, active: false),
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
            return PropagatingListener(
              onPointerDown: (event) {
                RiveContext.find(context).startDragOperation();
                _placePlayhead(context, event.pointerEvent.localPosition,
                    viewport, editingAnimation);
              },
              onPointerMove: (event) => _placePlayhead(context,
                  event.pointerEvent.localPosition, viewport, editingAnimation),
              onPointerUp: (event) {
                RiveContext.find(context).endDragOperation();
              },
              child: SizedBox(
                height: height,
                child: ValueStreamBuilder<WorkAreaViewModel>(
                  stream: editingAnimation.workArea,
                  builder: (context, snapshot) {
                    var theme = RiveTheme.of(context);
                    return snapshot.hasData
                        ? CustomMultiChildLayout(
                            delegate: _WorkAreaLayoutDelegate(
                              workArea: snapshot.data,
                              viewport: viewport,
                              theme: theme,
                            ),
                            children: [
                              LayoutId(
                                id: _WorkAreaLayoutPart.ticksRenderer,
                                child: _TimelineTicksRenderer(
                                  viewport,
                                  theme,
                                  snapshot.data,
                                ),
                              ),
                              if (snapshot.data.active)
                                LayoutId(
                                  id: _WorkAreaLayoutPart.start,
                                  child: OverlayHitDetect(
                                    customCursorIcon:
                                        PackedIcon.cursorResizeHorizontal,
                                    dragContext: context,
                                    endDrag:
                                        editingAnimation.captureJournalEntry,
                                    drag: (absolute, _) => _dragWorkAreaMarker(
                                      context,
                                      absolute,
                                      theme,
                                      viewport,
                                      (frame) {
                                        editingAnimation.changeWorkArea.add(
                                          WorkAreaViewModel(
                                            start: frame
                                                .clamp(0, snapshot.data.end - 1)
                                                .toInt(),
                                            end: snapshot.data.end,
                                            active: snapshot.data.active,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              if (snapshot.data.active)
                                LayoutId(
                                  id: _WorkAreaLayoutPart.end,
                                  child: OverlayHitDetect(
                                    customCursorIcon:
                                        PackedIcon.cursorResizeHorizontal,
                                    dragContext: context,
                                    endDrag:
                                        editingAnimation.captureJournalEntry,
                                    drag: (absolute, _) => _dragWorkAreaMarker(
                                        context, absolute, theme, viewport,
                                        (frame) {
                                      editingAnimation.changeWorkArea.add(
                                        WorkAreaViewModel(
                                          start: snapshot.data.start,
                                          end: frame
                                              .clamp(
                                                snapshot.data.start + 1,
                                                editingAnimation
                                                    .animation.duration,
                                              )
                                              .toInt(),
                                          active: snapshot.data.active,
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                            ],
                          )
                        : _buildEmpty(context);
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _dragWorkAreaMarker(
      BuildContext context,
      Offset dragPosition,
      RiveThemeData theme,
      TimelineViewport viewport,
      void Function(int frame) callback) {
    var marginLeft = theme.dimensions.timelineMarginLeft;
    var marginRight = theme.dimensions.timelineMarginRight;
    var normalized = (dragPosition.dx - marginLeft) /
        (context.size.width - marginLeft - marginRight);
    callback(((viewport.startSeconds +
                (viewport.endSeconds - viewport.startSeconds) * normalized) *
            viewport.fps)
        .round());
  }

  void _placePlayhead(BuildContext context, Offset offset,
      TimelineViewport viewport, EditingAnimationManager manager) {
    var renderObject = context.findRenderObject() as RenderBox;
    var theme = RiveTheme.of(context);

    var marginLeft = theme.dimensions.timelineMarginLeft;
    var marginRight = theme.dimensions.timelineMarginRight;
    var visibleDuration = viewport.endSeconds - viewport.startSeconds;
    var secondsPerPixel =
        visibleDuration / (renderObject.size.width - marginLeft - marginRight);
    var time =
        viewport.startSeconds + (offset.dx - marginLeft) * secondsPerPixel;
    manager.changeCurrentTime.add(time);
    // If an animation is playing, stop
    manager.changePlayback.add(false);
  }
}

enum _WorkAreaLayoutPart {
  ticksRenderer,
  start,
  end,
}

class _WorkAreaLayoutDelegate extends MultiChildLayoutDelegate {
  final WorkAreaViewModel workArea;
  final TimelineViewport viewport;
  final RiveThemeData theme;

  _WorkAreaLayoutDelegate({
    @required this.workArea,
    @required this.viewport,
    @required this.theme,
  });

  @override
  void performLayout(Size size) {
    layoutChild(
      _WorkAreaLayoutPart.ticksRenderer,
      BoxConstraints.tightFor(
        width: size.width,
        height: size.height,
      ),
    );
    positionChild(_WorkAreaLayoutPart.ticksRenderer, Offset.zero);

    if (!hasChild(_WorkAreaLayoutPart.end) ||
        !hasChild(_WorkAreaLayoutPart.start)) {
      return;
    }
    var marginLeft = theme.dimensions.timelineMarginLeft;
    var marginRight = theme.dimensions.timelineMarginRight;
    var visibleDuration = viewport.endSeconds - viewport.startSeconds;
    var secondsPerPixel =
        visibleDuration / (size.width - marginLeft - marginRight);

    var hitAreaOffset = -TimelineTicks.workAreaGrabberWidth / 2;
    double baseLine = size.height - TimelineTicks.workAreaGrabberHeight;

    var offsetStart = Offset(
        (marginLeft +
                    (workArea.start / viewport.fps - viewport.startSeconds) /
                        secondsPerPixel +
                    hitAreaOffset)
                .roundToDouble() +
            0.5,
        baseLine);
    var offsetEnd = Offset(
        (marginLeft +
                    (workArea.end / viewport.fps - viewport.startSeconds) /
                        secondsPerPixel +
                    hitAreaOffset)
                .roundToDouble() +
            0.5,
        baseLine);

    layoutChild(
      _WorkAreaLayoutPart.start,
      offsetStart.dx < -TimelineTicks.workAreaGrabberWidth ||
              offsetStart.dx > size.width
          ? const BoxConstraints.tightFor(width: 0, height: 0)
          : const BoxConstraints.tightFor(
              width: TimelineTicks.workAreaGrabberWidth,
              height: TimelineTicks.workAreaGrabberHeight,
            ),
    );

    positionChild(
      _WorkAreaLayoutPart.start,
      offsetStart,
    );

    layoutChild(
      _WorkAreaLayoutPart.end,
      offsetEnd.dx < -TimelineTicks.workAreaGrabberWidth ||
              offsetEnd.dx > size.width
          ? const BoxConstraints.tightFor(width: 0, height: 0)
          : const BoxConstraints.tightFor(
              width: TimelineTicks.workAreaGrabberWidth,
              height: TimelineTicks.workAreaGrabberHeight,
            ),
    );
    positionChild(_WorkAreaLayoutPart.end, offsetEnd);
  }

  @override
  bool shouldRelayout(_WorkAreaLayoutDelegate oldDelegate) =>
      oldDelegate.workArea != workArea || oldDelegate.viewport != viewport;
}

class _TimelineTicksRenderer extends LeafRenderObjectWidget {
  final TimelineViewport viewport;
  final RiveThemeData theme;
  final WorkAreaViewModel workArea;

  const _TimelineTicksRenderer(
    this.viewport,
    this.theme,
    this.workArea,
  );

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _TimelineTicksRenderObject()
      ..viewport = viewport
      ..workArea = workArea
      ..theme = theme;
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant _TimelineTicksRenderObject renderObject) {
    renderObject
      ..viewport = viewport
      ..workArea = workArea
      ..theme = theme;
  }
}

class _TimelineTicksRenderObject extends TimelineRenderBox {
  static const double tickHeight = 5;
  static const double workAreaMarkerWidth = 5;
  static const double halfMarkerWidth = workAreaMarkerWidth / 2;
  static const double markerWallHeight = 8;
  static const double markerCornerRadius = 1;

  final List<Paragraph> _ticks = [];

  // /----\
  // |    |
  // |    |
  //   \/

  //.     .
  //     \    .
  //      \
  //          .
  final Path workAreaTick = Path()
    // Bottom Triangle
    ..moveTo(-halfMarkerWidth, 0)
    ..lineTo(0, 2)
    ..lineTo(halfMarkerWidth, 0)
    ..lineTo(halfMarkerWidth, -markerWallHeight)
    ..cubicTo(
        halfMarkerWidth,
        -markerWallHeight - markerCornerRadius * circleConstant,
        halfMarkerWidth - (1 - markerCornerRadius * circleConstant),
        -markerWallHeight - markerCornerRadius,
        halfMarkerWidth - markerCornerRadius,
        -markerWallHeight - markerCornerRadius)
    ..lineTo(-halfMarkerWidth + markerCornerRadius,
        -markerWallHeight - markerCornerRadius)
    ..cubicTo(
        -halfMarkerWidth + (1 - markerCornerRadius * circleConstant),
        -markerWallHeight - markerCornerRadius,
        -halfMarkerWidth,
        -markerWallHeight -
            markerCornerRadius +
            (1 - markerCornerRadius * circleConstant),
        -halfMarkerWidth,
        -markerWallHeight)
    ..close();
  final Paint markerPaint = Paint();

  /// Try to not rebuild paragraphs, cache them between layouts as usually we'll
  /// be scrolling and won't need to rebuild the whole set.
  HashMap<String, Paragraph> _paragraphCache = HashMap<String, Paragraph>();

  double _left = 0;
  double _tickWidth = 1;

  Paint _background;
  Paint _line;
  WorkAreaViewModel _workArea;
  WorkAreaViewModel get workArea => _workArea;
  set workArea(WorkAreaViewModel value) {
    if (_workArea == value) {
      return;
    }
    _workArea = value;
    markNeedsPaint();
  }

  @override
  void onThemeChanged(RiveThemeData theme) {
    markerPaint.color = theme.colors.timelineViewportControlsGrabber;
    _background = Paint()..color = theme.colors.timelineBackground;
    _line = Paint()
      ..color = theme.colors.timelineLine
      ..isAntiAlias = false
      ..strokeWidth = 1;
  }

  @override
  void performLayout() {
    super.performLayout();
    if (viewport == null) {
      return;
    }

    var marginLeft = theme.dimensions.timelineMarginLeft;

    int idealTickWidth = 100;
    var secondsPerIdeal = secondsPerPixel * idealTickWidth;

    var unitsPerTick = secondsPerIdeal;
    var pixelsPerUnit = secondsPerPixel;
    var label = "s";
    var startInUnits = viewport.startSeconds;
    var rate = 60; // 60 seconds per minute

    if (unitsPerTick < 1) {
      unitsPerTick = secondsPerIdeal * viewport.fps;
      pixelsPerUnit = secondsPerPixel * viewport.fps;
      startInUnits = startInUnits * viewport.fps;
      label = "f";
      rate = viewport.fps;
    } else if (unitsPerTick > 60) {
      unitsPerTick = secondsPerIdeal / 60;
      pixelsPerUnit = secondsPerPixel / 60;
      startInUnits = startInUnits / 60;
      label = "m";
      rate = 3600; // seconds per hour
    } else if (unitsPerTick > 3600) {
      unitsPerTick = secondsPerIdeal / 3600;
      pixelsPerUnit = secondsPerPixel / 3600;
      startInUnits = startInUnits / 3600;
      label = "h";
      rate = 60 * 60 * 24; // seconds per day
    }

    if (unitsPerTick < 1) {
      unitsPerTick = 1;
    } else if (unitsPerTick < 3) {
      unitsPerTick = 2;
    } else {
      // Round to the closest 5
      unitsPerTick = (unitsPerTick / 5).roundToDouble() * 5;
      // Make sure it's a whole factor.
      unitsPerTick = rate / (rate / unitsPerTick).round();
    }

    _tickWidth = unitsPerTick / pixelsPerUnit;
    var numberOfTicks = (size.width / _tickWidth + 1).ceil();

    var startInTicks = startInUnits / unitsPerTick;
    var tickValue = startInTicks.floor() * unitsPerTick;
    //var left = startInUnits / unitsPerTick;
    _ticks.clear();
    _left = -(startInTicks % 1) * _tickWidth + marginLeft;

    var textStyle = theme.textStyles.timelineTicks;
    final style = textStyle.getParagraphStyle(textAlign: TextAlign.left);
    final constraints = ParagraphConstraints(width: _tickWidth);

    final nextCache = HashMap<String, Paragraph>();
    for (var i = 0; i < numberOfTicks; i++) {
      String valueString;
      var v = (tickValue % rate).floor();
      if (v == 0) {
        v = (tickValue / rate).floor();
        v %= 60;
        valueString = v.toString().padLeft(2, '0') + ':00s';
      } else {
        valueString = v.toString() + label;
      }
      // Already have it?
      Paragraph paragraph = _paragraphCache[valueString];
      if (paragraph == null) {
        // Didn't already have it, rebuild.
        ParagraphBuilder builder = ParagraphBuilder(style);
        builder.pushStyle(textStyle.getTextStyle());
        builder.addText(valueString);
        paragraph = builder.build();
        paragraph.layout(constraints);
      }
      nextCache[valueString] = paragraph;

      _ticks.add(paragraph);
      tickValue += unitsPerTick;
    }
    _paragraphCache = nextCache;
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
        RRect.fromRectAndCorners(
          offset & size,
          topLeft: const Radius.circular(5),
          topRight: const Radius.circular(5),
        ),
        _background);

    // Draw ticks.
    var tickPos = offset + Offset(_left, size.height);
    const tickHeightOffset = Offset(0, -tickHeight);
    final tickIncOffset = Offset(_tickWidth, 0);
    final labelOffset = Offset(6, -theme.textStyles.timelineTicks.fontSize - 4);

    canvas.save();
    canvas.clipRect(offset & Size(size.width, size.height + 3));
    for (final tick in _ticks) {
      var renderOffset = Offset(tickPos.dx.roundToDouble() + 0.5, tickPos.dy);

      canvas.drawLine(renderOffset, renderOffset + tickHeightOffset, _line);

      canvas.drawParagraph(
        tick,
        renderOffset + labelOffset,
      );
      tickPos += tickIncOffset;
    }

    canvas.drawLine(offset + Offset(0, size.height - 0.5),
        offset + Offset(size.width + 0.5, size.height - 0.5), _line);

    // Draw work area if necessary
    if (_workArea.active) {
      var marginLeft = theme.dimensions.timelineMarginLeft;
      canvas.save();
      canvas.translate(
          (offset.dx +
                      marginLeft +
                      (_workArea.start / viewport.fps - viewport.startSeconds) /
                          secondsPerPixel)
                  .roundToDouble() +
              0.5,
          offset.dy + size.height);

      canvas.drawPath(workAreaTick, markerPaint);
      canvas.restore();

      canvas.save();
      canvas.translate(
          (offset.dx +
                      marginLeft +
                      (_workArea.end / viewport.fps - viewport.startSeconds) /
                          secondsPerPixel)
                  .roundToDouble() +
              0.5,
          offset.dy + size.height);

      canvas.drawPath(workAreaTick, markerPaint);

      canvas.restore();
    }

    canvas.restore();
    //     canvas.save();
    //     canvas.translate(0, -100);
    //     canvas.scale(50);
    // canvas.drawPath(workAreaTick, Paint()..color = const Color(0xFFFF0000));
    // canvas.restore();
  }
}
