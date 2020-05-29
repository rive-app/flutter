import 'package:rive/src/core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

abstract class RiveAnimationController {
  final _isPlaying = ValueNotifier<bool>(false);
  ValueListenable<bool> get isPlayingChanged => _isPlaying;
  bool get isPlaying => _isPlaying.value;
  set isPlaying(bool value) {
    if (_isPlaying.value != value) {
      _isPlaying.value = value;
      if (value) {
        onPlay();
      } else {
        onStop();
      }
    }
  }

  @protected
  void onPlay();
  @protected
  void onStop();
  void apply(CoreContext core, double elapsedSeconds);
  bool init(CoreContext core) => true;
  void dispose();
}
