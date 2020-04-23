import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:rive_core/animation/linear_animation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:meta/meta.dart';

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

  EditingAnimationManager(this.editingAnimation) {
    _timeStream.add(0);
    _fpsStream.add(editingAnimation.fps);
    _fpsController.stream.listen(_changeFps);
    _fpsPreviewController.stream.listen(_changePreviewFps);
    editingAnimation.addListener(
        LinearAnimationBase.fpsPropertyKey, _coreFpsChanged);
  }

  ValueNotifier<TimelineViewport> viewport =
      ValueNotifier<TimelineViewport>(const TimelineViewport(0.0, 10.0, 30.0));

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

  ValueStream<int> get currentTime => _timeStream;
  ValueStream<int> get fps => _fpsStream;
  Sink<int> get previewRateChange => _fpsPreviewController;

  void dispose() {
    editingAnimation.removeListener(
        LinearAnimationBase.fpsPropertyKey, _coreFpsChanged);
    _timeController.close();
    _timeStream.close();
    _fpsController.close();
    _fpsPreviewController.close();
  }
}

@immutable
class TimelineViewport {
  final double startSeconds;
  final double endSeconds;
  final double totalSeconds;

  const TimelineViewport(this.startSeconds, this.endSeconds, this.totalSeconds)
      : assert(startSeconds <= endSeconds);

  TimelineViewport zoom(double start, double end) =>
      TimelineViewport(start, end, totalSeconds);
}
