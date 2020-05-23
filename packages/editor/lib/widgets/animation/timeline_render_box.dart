import 'package:flutter/widgets.dart';
import 'package:rive_editor/rive/managers/animation/animation_time_manager.dart';
import 'package:rive_editor/widgets/theme.dart';

/// All timeline renderers need to be in viewport space, so this common
/// abstraction of the RenderBox pre-computes values needed for that for all
/// timeline renderers (like the ticks, timeline keys, playhead, etc).
abstract class TimelineRenderBox extends RenderBox {
  TimelineViewport _viewport;
  RiveThemeData _theme;
  double _secondsPerPixel;

  double _secondsStart;
  double get secondsStart => _secondsStart;

  double get secondsPerPixel => _secondsPerPixel;
  RiveThemeData get theme => _theme;
  set theme(RiveThemeData value) {
    if (value == _theme) {
      return;
    }
    _theme = value;

    onThemeChanged(value);
    markNeedsPaint();
  }

  void onThemeChanged(RiveThemeData theme);

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

    var marginLeft = theme.dimensions.timelineMarginLeft;
    var marginRight = theme.dimensions.timelineMarginRight;

    var visibleDuration = _viewport.endSeconds - _viewport.startSeconds;
    _secondsPerPixel =
        visibleDuration / (size.width - marginLeft - marginRight);

    // This is the time at local x 0
    _secondsStart = viewport.startSeconds - marginLeft * secondsPerPixel;
  }

  double framesToPixels(int frames) =>
      ((frames / _viewport.fps - _secondsStart) / _secondsPerPixel)
          .roundToDouble();
}
