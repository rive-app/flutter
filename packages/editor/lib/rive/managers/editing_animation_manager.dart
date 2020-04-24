import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:rive_core/animation/linear_animation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:meta/meta.dart';

/// Animation manager for the currently editing [LinearAnimation].
class EditingAnimationManager {
  final LinearAnimation editingAnimation;

  final _fpsStream = BehaviorSubject<int>();

  /// Use this to actually process the final fps rate change.
  final _fpsController = StreamController<int>();

  /// Use this to preview the rate change but don't commit the change (convert
  /// the various dependent values and capture).
  final _fpsPreviewController = StreamController<int>();
  final _timeStream = BehaviorSubject<int>();

  final _timeController = StreamController<double>();
  final _viewportController = StreamController<TimelineViewport>();

  EditingAnimationManager(this.editingAnimation) {
    /// TODO: compute real viewport and min seconds should be 2 frames in
    /// seconds. Sync this whenever duration, fps, etc change.
    _viewportStream.add(const TimelineViewport(5.0, 10.0, 30.0, 0.1));
    _timeStream.add(0);
    _fpsStream.add(editingAnimation.fps);
    _fpsController.stream.listen(_changeFps);
    _fpsPreviewController.stream.listen(_changePreviewFps);
    editingAnimation.addListener(
        LinearAnimationBase.fpsPropertyKey, _coreFpsChanged);

    _viewportController.stream.listen(_changeViewport);
  }

  void _changeViewport(TimelineViewport viewport) {
    _viewportStream.add(viewport);
    // TODO: change core properties...
  }

  final _viewportStream = BehaviorSubject<TimelineViewport>();
  ValueStream<TimelineViewport> get viewport => _viewportStream;

  void _coreFpsChanged(dynamic from, dynamic to) {
    _fpsStream.add(to as int);
  }

  void _changePreviewFps(int value) {
    _fpsStream.add(value);
  }

  void _changeFps(int value) {
    int oldFps = editingAnimation.fps;
    print("MAKE THE CHANGE $oldFps => $value");
    // When the FPS of the animation changes we need to update all properties
    // that are in frame value (like duration) and keyframe time values.

    // TODO: don't forget to captureJournalEntry
  }

  /// Change the current time displayed (value is in seconds).
  Sink<double> get changeCurrentTime => _timeController;

  /// Change the fps of the current animation.
  Sink<int> get changeRate => _fpsController;

  /// Change the current viewport
  Sink<TimelineViewport> get changeViewport => _viewportController;

  ValueStream<int> get currentTime => _timeStream;
  ValueStream<int> get fps => _fpsStream;
  Sink<int> get previewRateChange => _fpsPreviewController;

  void dispose() {
    _viewportController.close();
    _viewportStream.close();
    editingAnimation.removeListener(
        LinearAnimationBase.fpsPropertyKey, _coreFpsChanged);
    _timeController.close();
    _timeStream.close();
    _fpsController.close();
    _fpsPreviewController.close();
  }
}

/// Effectively the view model for the currently visible animation viewport.
/// Contains the start, end, duration, and a minimum value which should be set
/// to 2 frames computed in seconds.
@immutable
class TimelineViewport {
  final double startSeconds;
  final double endSeconds;
  final double totalSeconds;
  final double minSeconds;

  const TimelineViewport(
      this.startSeconds, this.endSeconds, this.totalSeconds, this.minSeconds);

  /// Move the start of the viewport, clamping at end.
  TimelineViewport moveStart(double value) => TimelineViewport(
      min(value, endSeconds - minSeconds),
      endSeconds,
      totalSeconds,
      minSeconds);

  /// Move the start of the viewport, clamping at start.
  TimelineViewport moveEnd(double value) => TimelineViewport(startSeconds,
      max(value, startSeconds + minSeconds), totalSeconds, minSeconds);

  /// Move the viewport, clamping at edges.
  TimelineViewport move(double value) {
    double shiftSeconds = value;
    double check = startSeconds + shiftSeconds;
    if (check < 0) {
      shiftSeconds -= check;
    }
    check = endSeconds + shiftSeconds;
    if (check > totalSeconds) {
      shiftSeconds = value - (check - totalSeconds);
    }
    return TimelineViewport(startSeconds + shiftSeconds,
        endSeconds + shiftSeconds, totalSeconds, minSeconds);
  }
}
