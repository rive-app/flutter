import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:rive_core/src/generated/rive_core_context.dart';
export 'package:rive_core/src/generated/rive_core_context.dart';

/// Abstraction for receiving a per frame callback while isPlaying is true to
/// apply animation based on an elapsed amount of time.
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

  /// Apply animation to objects registered in [core]. Note that a [core]
  /// context is specified as animations can be applied to instances.
  void apply(RiveCoreContext core, double elapsedSeconds);

  bool init(RiveCoreContext core) => true;
  void dispose();
}
