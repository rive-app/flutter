import 'dart:collection';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:rive_editor/rive/managers/animation/animation_time_manager.dart';
import 'package:rive_editor/widgets/common/value_stream_builder.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/theme.dart';

/// A guide view on the top of the timeline that shows the current viewport
/// range, makes it easy to line up keyframes. Works based off the current
/// viewport and ticks are aligned to frame rate. TODO: support workspace.
class TimelineTicks extends StatelessWidget {
  static const double height = 19;

  /// Draw the same background for the controls even if we don't have a
  /// currently editing animation.
  Widget _buildEmpty(BuildContext context) {
    return SizedBox(
      height: height,
      child: _TimelineTicksRenderer(
        null,
        RiveTheme.of(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var editingAnimation = EditingAnimationProvider.of(context);
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
          child: _TimelineTicksRenderer(
            viewport,
            RiveTheme.of(context),
          ),
        );
      },
    );
  }
}

class _TimelineTicksRenderer extends LeafRenderObjectWidget {
  final TimelineViewport viewport;
  final RiveThemeData theme;

  const _TimelineTicksRenderer(
    this.viewport,
    this.theme,
  );

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _TimelineTicksRenderObject()
      ..viewport = viewport
      ..theme = theme;
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant _TimelineTicksRenderObject renderObject) {
    renderObject
      ..viewport = viewport
      ..theme = theme;
  }

  @override
  void didUnmountRenderObject(
      covariant _TimelineTicksRenderObject renderObject) {
    // Any cleanup to do here?
  }
}

class _TimelineTicksRenderObject extends RenderBox {
  static const double marginLeft = 10;
  static const double marginRight = 30;
  static const double tickHeight = 5;

  final List<Paragraph> _ticks = [];

  /// Try to not rebuild paragraphs, cache them between layouts as usually we'll
  /// be scrolling and won't need to rebuild the whole set.
  HashMap<String, Paragraph> _paragraphCache = HashMap<String, Paragraph>();

  double _left = 0;
  double _tickWidth = 1;

  TimelineViewport _viewport;
  RiveThemeData _theme;

  Paint _background;
  Paint _line;

  RiveThemeData get theme => _theme;
  set theme(RiveThemeData value) {
    if (value == _theme) {
      return;
    }
    _theme = value;
    _background = Paint()..color = value.colors.timelineBackground;
    _line = Paint()
      ..color = value.colors.timelineLine
      ..isAntiAlias = false
      ..strokeWidth = 1;

    markNeedsPaint();
  }

  TimelineViewport get viewport => _viewport;
  set viewport(TimelineViewport value) {
    if (_viewport == value) {
      return;
    }
    _viewport = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    super.performLayout();
    if (_viewport == null) {
      return;
    }
    var visibleDuration = _viewport.endSeconds - _viewport.startSeconds;
    var secondsPerPixel =
        visibleDuration / (size.width - marginLeft - marginRight);
    int idealTickWidth = 100;
    var secondsPerIdeal = secondsPerPixel * idealTickWidth;

    var unitsPerTick = secondsPerIdeal;
    var pixelsPerUnit = secondsPerPixel;
    var label = "s";
    var startInUnits = _viewport.startSeconds;
    var rate = 60; // 60 seconds per minute

    if (unitsPerTick < 1) {
      unitsPerTick = secondsPerIdeal * _viewport.fps;
      pixelsPerUnit = secondsPerPixel * _viewport.fps;
      startInUnits = startInUnits * _viewport.fps;
      label = "f";
      rate = _viewport.fps;
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
    canvas.clipRect(offset & size);
    for (final tick in _ticks) {
      canvas.drawLine(tickPos, tickPos + tickHeightOffset, _line);
      canvas.drawParagraph(
        tick,
        tickPos + labelOffset,
      );
      tickPos += tickIncOffset;
    }
    canvas.restore();
    canvas.drawLine(offset + Offset(0, size.height - 0.5),
        offset + Offset(size.width, size.height - 0.5), _line);
  }
}
