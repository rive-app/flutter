import 'dart:async';
import 'dart:math';

import 'package:core/debounce.dart';
import 'package:flutter/widgets.dart';
import 'package:rive_core/animation/linear_animation.dart';
import 'package:rive_editor/rive/managers/animation/animation_manager.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rxdart/rxdart.dart';
import 'package:meta/meta.dart';
import 'package:rive_core/rive_animation_controller.dart';

class _SimpleAnimationController extends RiveAnimationController {
  final LinearAnimation animation;
  VoidCallback onTimeChanged;
  _SimpleAnimationController(this.animation, this.onTimeChanged);

  // This controller distinguishes between playing an animation (sustained
  // playback) and applying a single frame (isPlaying).
  bool _sustainedPlayback = false;
  bool get sustainedPlayback => _sustainedPlayback;
  set sustainedPlayback(bool value) {
    if (value == _sustainedPlayback) {
      return;
    }
    _sustainedPlayback = value;
    isPlaying = true;
  }

  double time = 0;
  @override
  void apply(RiveCoreContext core, double elapsedSeconds) {
    // Reset all previously animated properties.
    core.resetAnimation();
    animation.apply(time, coreContext: core);

    if (_sustainedPlayback) {
      time += elapsedSeconds * animation.speed;
      isPlaying = true;
      onTimeChanged();
    } else {
      // after apply, pause
      isPlaying = false;
    }
  }

  @override
  void dispose() {}

  @override
  void onPlay() {}

  @override
  void onStop() {}
}

/// Time manager for the currently editing [LinearAnimation]. Allows controlling
/// the viewport, changing animation duration, and tracking editing animation
/// time.
abstract class AnimationTimeManager extends AnimationManager {
  final OpenFileContext activeFile;
  final _fpsStream = BehaviorSubject<int>();

  /// Use this to actually process the final fps rate change.
  final _fpsController = StreamController<int>();

  /// Use this to preview the rate change but don't commit the change (convert
  /// the various dependent values and capture).
  final _fpsPreviewController = StreamController<int>();
  final _timeStream = BehaviorSubject<double>();

  final _timeController = StreamController<double>();
  final _viewportController = StreamController<TimelineViewport>();

  final _isPlayingStream = BehaviorSubject<bool>();
  final _playbackController = StreamController<bool>();

  _SimpleAnimationController _controller;
  AnimationTimeManager(LinearAnimation animation, this.activeFile)
      : super(animation) {
    _controller = _SimpleAnimationController(animation, () {
      double frames = _controller.time*animation.fps;
      if( animation.duration-frames < 0) {
        _changePlayback(false);
      }
      _timeStream.add(frames
          .clamp(0, animation.duration)
          .toDouble());
    });
    animation.artboard.addController(_controller);
    _controller.isPlaying = true;

    _isPlayingStream.add(false);
    _timeStream.add(0);
    _fpsStream.add(animation.fps);
    _fpsController.stream.listen(_changeFps);
    _timeController.stream.listen(_changeCurrentTime);
    _fpsPreviewController.stream.listen(_changePreviewFps);
    animation.addListener(LinearAnimationBase.fpsPropertyKey, _coreFpsChanged);
    animation.addListener(
        LinearAnimationBase.durationPropertyKey, _coreDurationChange);
    _viewportController.stream.listen(_changeViewport);
    _playbackController.stream.listen(_changePlayback);
    animation.keyframesChanged.addListener(_keyframesChanged);

    _syncViewport();

    activeFile.addActionHandler(_handleAction);
  }

  void _keyframesChanged() {
    // _controller.apply(animation.context, 0);
    _controller.isPlaying = true;
  }

  void _syncViewport() {
    double start = min(animation.duration / animation.fps - 2 / animation.fps,
        _viewportStream.hasValue ? _viewportStream.value.startSeconds : 0);
    double end = min(
        animation.duration / animation.fps,
        _viewportStream.hasValue
            ? _viewportStream.value.endSeconds
            : animation.duration / animation.fps);

    _viewportStream.add(TimelineViewport(
        start, end, animation.duration / animation.fps, animation.fps));
  }

  void _changePlayback(bool play) {
    _controller.sustainedPlayback = play;
    _isPlayingStream.add(play);
  }

  void _changeViewport(TimelineViewport viewport) {
    _viewportStream.add(viewport);
    // TODO: change core properties...
  }

  final _viewportStream = BehaviorSubject<TimelineViewport>();
  ValueStream<TimelineViewport> get viewport => _viewportStream;
  ValueStream<bool> get isPlaying => _isPlayingStream;

  void _coreDurationChange(dynamic from, dynamic to) => debounce(_syncViewport);
  void _coreFpsChanged(dynamic from, dynamic to) {
    _fpsStream.add(to as int);
    debounce(_syncViewport);
  }

  void _changePreviewFps(int value) {
    _fpsStream.add(value);
  }

  /// Value is in seconds, quantize to nearest frame.
  void _changeCurrentTime(double value) {
    var frame =
        (value * animation.fps).clamp(0, animation.duration).roundToDouble();
    _controller.time = frame / animation.fps;
    _controller.isPlaying = true;
    _timeStream.add(frame);
  }

  void _changeFps(int value) {
    int oldFps = animation.fps;

    // When the FPS of the animation changes we need to update all properties
    // that are in frame value (like duration) and keyframe time values.
    animation.duration = ((animation.duration / oldFps) * value).round();
    animation.fps = value;
    animation.context.captureJournalEntry();
  }

  /// Change the current time displayed (value is in seconds).
  Sink<double> get changeCurrentTime => _timeController;

  /// Change the fps of the current animation.
  Sink<int> get changeRate => _fpsController;

  /// Change the current viewport
  Sink<TimelineViewport> get changeViewport => _viewportController;

  /// Change whether this animation is playing.
  Sink<bool> get changePlayback => _playbackController;

  ValueStream<double> get currentTime => _timeStream;
  ValueStream<int> get fps => _fpsStream;
  Sink<int> get previewRateChange => _fpsPreviewController;

  /// Get the closest frame to the current playhead.
  int get frame => _timeStream.value.floor();

  void dispose() {
    activeFile.removeActionHandler(_handleAction);
    animation.artboard.removeController(_controller);
    animation.keyframesChanged.removeListener(_keyframesChanged);

    cancelDebounce(_syncViewport);
    _viewportController.close();
    _playbackController.close();
    _isPlayingStream.close();
    _viewportStream.close();
    animation.removeListener(
        LinearAnimationBase.fpsPropertyKey, _coreFpsChanged);
    animation.removeListener(
        LinearAnimationBase.durationPropertyKey, _coreDurationChange);
    _timeController.close();
    _timeStream.close();
    _fpsController.close();
    _fpsPreviewController.close();
  }

  bool _handleAction(ShortcutAction action) {
    switch (action) {
      case ShortcutAction.togglePlay:
        bool play = !_isPlayingStream.value;
        // If we're super close to the end, rewing to start before playing.
        if (play &&
            (_timeStream.value - animation.duration).abs() <
                0.01) {
          _controller.time = 0;
        }
        _changePlayback(play);
        return true;
    }
    return false;
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
  final int fps;

  double get minSeconds => 2 / fps;

  const TimelineViewport(
      this.startSeconds, this.endSeconds, this.totalSeconds, this.fps);

  /// Move the start of the viewport, clamping at end.
  TimelineViewport moveStart(double value) => TimelineViewport(
      min(value, endSeconds - minSeconds), endSeconds, totalSeconds, fps);

  /// Move the start of the viewport, clamping at start.
  TimelineViewport moveEnd(double value) => TimelineViewport(
      startSeconds, max(value, startSeconds + minSeconds), totalSeconds, fps);

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
        endSeconds + shiftSeconds, totalSeconds, fps);
  }
}
