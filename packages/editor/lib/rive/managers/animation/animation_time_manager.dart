import 'dart:async';
import 'dart:math';

import 'package:core/core.dart';
import 'package:core/debounce.dart';
import 'package:flutter/widgets.dart';
import 'package:rive_core/animation/linear_animation.dart';
import 'package:rive_core/animation/linear_animation_instance.dart';
import 'package:rive_core/animation/loop.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_editor/rive/managers/animation/animation_manager.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rxdart/rxdart.dart';
import 'package:meta/meta.dart';
import 'package:rive_core/rive_animation_controller.dart';

class _SimpleAnimationController
    extends RiveAnimationController<RiveCoreContext> {
  final LinearAnimation animation;
  final LinearAnimationInstance animationInstance;
  void Function(double) onTimeChanged;
  _SimpleAnimationController(this.animation, this.onTimeChanged)
      : animationInstance = LinearAnimationInstance(animation);

  // This controller distinguishes between playing an animation (sustained
  // playback) and applying a single frame (isPlaying).
  bool _sustainedPlayback = false;
  bool get sustainedPlayback => _sustainedPlayback;
  set sustainedPlayback(bool value) {
    if (value == _sustainedPlayback) {
      return;
    }
    _sustainedPlayback = value;
    if (value) {
      // If we're out of range, start playing from start.
      var start = animation.enableWorkArea ? animation.workStart : 0;
      var end =
          animation.enableWorkArea ? animation.workEnd : animation.duration;
      double frames = animationInstance.time * animation.fps;
      if (frames < start) {
        frames = start.toDouble();
        time = frames / animation.fps;
      } else if (frames > end) {
        frames = start.toDouble();
        time = frames / animation.fps;
      }
    }

    // Always advance/apply next frame.
    isActive = true;
  }

  double get time => animationInstance.time;
  set time(double value) => animationInstance.time = value;

  @override
  void apply(CoreContext core, double elapsedSeconds) {
    // Reset all previously animated properties.
    core.resetAnimation();
    animation.apply(animationInstance.time, coreContext: core);

    if (_sustainedPlayback) {
      if (!animationInstance.advance(elapsedSeconds)) {
        _sustainedPlayback = false;
      }
      isActive = true;
      onTimeChanged(animationInstance.time * animation.fps);
    } else {
      // after apply, pause
      isActive = false;
    }
  }

  @override
  void dispose() {}

  @override
  void onActivate() {}

  @override
  void onDeactivate() {}
}

/// Time manager for the currently editing [LinearAnimation]. Allows controlling
/// the viewport, changing animation duration, and tracking editing animation
/// time.
abstract class AnimationTimeManager extends AnimationManager {
  final OpenFileContext activeFile;
  final _fpsStream = BehaviorSubject<int>();

  final _workArea = BehaviorSubject<WorkAreaViewModel>();
  final _workAreaController = StreamController<WorkAreaViewModel>();

  final _loop = BehaviorSubject<Loop>();
  final _loopController = StreamController<Loop>();
  // Use this to gate whether or not to update the stream (when we update
  // internally we may be changing multiple properties and not want to trigger
  // an update for each one).
  bool _suppressSyncWorkArea = false;

  ValueStream<WorkAreaViewModel> get workArea => _workArea;
  Sink<WorkAreaViewModel> get changeWorkArea => _workAreaController;

  ValueStream<Loop> get loop => _loop;
  Sink<Loop> get changeLoop => _loopController;

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
  Artboard _artboard;
  AnimationTimeManager(LinearAnimation animation, this.activeFile)
      : super(animation) {
    _controller = _SimpleAnimationController(animation, (frames) {
      _changePlayback(_controller.sustainedPlayback);
      _timeStream.add(frames.clamp(0, animation.duration).toDouble());
    });
    _artboard = animation.artboard;
    _artboard.addController(_controller);
    _controller.isActive = true;

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
    animation.keyframeValueChanged.addListener(_keyframesChanged);

    animation.addListener(LinearAnimationBase.enableWorkAreaPropertyKey,
        _workAreaPropertyChanged);
    animation.addListener(
        LinearAnimationBase.workStartPropertyKey, _workAreaPropertyChanged);
    animation.addListener(
        LinearAnimationBase.workEndPropertyKey, _workAreaPropertyChanged);

    animation.addListener(
        LinearAnimationBase.loopValuePropertyKey, _loopPropertyChanged);

    _syncViewport();
    _syncWorkArea();
    _syncLoop();

    activeFile.addReleaseActionHandler(_releaseAction);

    _workAreaController.stream.listen(_changeWorkArea);
    _loopController.stream.listen(_changeLoop);
  }

  void _changeLoop(Loop loop) {
    if (animation.loop == loop) {
      return;
    }
    animation.loop = loop;

    /// Whenever changing loop, set direction back to 1;
    _controller.animationInstance.direction = 1;
    animation.context.captureJournalEntry();
  }

  void _changeWorkArea(WorkAreaViewModel viewModel) {
    _suppressSyncWorkArea = true;
    animation.workStart = viewModel.start;
    animation.workEnd = viewModel.end;
    animation.enableWorkArea = viewModel.active;
    _suppressSyncWorkArea = false;
    _syncWorkArea();
  }

  void _syncLoop() {
    _loop.add(animation.loop);
  }

  void _loopPropertyChanged(dynamic from, dynamic to) {
    _syncLoop();
  }

  void _workAreaPropertyChanged(dynamic from, dynamic to) {
    if (_suppressSyncWorkArea) {
      return;
    }
    debounce(_syncWorkArea);
  }

  void _keyframesChanged() {
    // Whenever the keyframes change, we re-apply the current animation at the
    // current time. We do this by telling the controller to run and apply again
    // (setting isPlaying to true activates the controller).
    _controller.isActive = true;

    // In order to make sure anything depending on the current time also updates
    // we pipe through the current time again. See interpolation_preview.dart.
    _timeStream.add(_timeStream.value);
  }

  void _syncWorkArea() {
    if (!animation.enableWorkArea) {
      _workArea.add(const WorkAreaViewModel(active: false));
      return;
    }

    _workArea.add(WorkAreaViewModel(
      start: animation.workStart,
      end: animation.workEnd,
      active: animation.enableWorkArea,
    ));
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
    if (_isPlayingStream.value == play) {
      return;
    }
    _controller.sustainedPlayback = play;
    if (!play) {
      // We should round to the closest frame when we pause (fixes #469).
      _changeCurrentTime(_controller.time);
    }
    _isPlayingStream.add(play);
  }

  void _changeViewport(TimelineViewport viewport) {
    _viewportStream.add(viewport);
    // TODO: change core properties...
  }

  final _viewportStream = BehaviorSubject<TimelineViewport>();
  ValueStream<TimelineViewport> get viewport => _viewportStream;
  ValueStream<bool> get isPlaying => _isPlayingStream;

  void _coreDurationChange(dynamic from, dynamic to) {
    if (animation.workEnd != null) {
      animation.workEnd = min(animation.workEnd, animation.duration);
    }
    debounce(_syncViewport);
  }

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
    _controller.isActive = true;
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

  void captureJournalEntry() => animation.context.captureJournalEntry();

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
    cancelDebounce(_syncWorkArea);
    animation.removeListener(LinearAnimationBase.enableWorkAreaPropertyKey,
        _workAreaPropertyChanged);
    animation.removeListener(
        LinearAnimationBase.workStartPropertyKey, _workAreaPropertyChanged);
    animation.removeListener(
        LinearAnimationBase.workEndPropertyKey, _workAreaPropertyChanged);
    _workArea.close();
    _workAreaController.close();
    animation.removeListener(
        LinearAnimationBase.loopValuePropertyKey, _loopPropertyChanged);
    _loop.close();
    _loopController.close();
    activeFile.removeReleaseActionHandler(_releaseAction);
    _artboard.removeController(_controller);
    animation.keyframesChanged.removeListener(_keyframesChanged);
    animation.keyframeValueChanged.removeListener(_keyframesChanged);

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

  bool _releaseAction(ShortcutAction action) {
    switch (action) {
      case ShortcutAction.togglePlay:
        bool play = !_isPlayingStream.value;
        var start = animation.enableWorkArea ? animation.workStart : 0;
        var end =
            animation.enableWorkArea ? animation.workEnd : animation.duration;
        // If we're super close to the end, rewing to start before playing.
        if (play && (_timeStream.value - end).abs() < 0.01) {
          _controller.time = start / animation.fps;
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

@immutable
class WorkAreaViewModel {
  final int start, end;
  final bool active;

  const WorkAreaViewModel({
    this.start,
    this.end,
    this.active = false,
  });
}
