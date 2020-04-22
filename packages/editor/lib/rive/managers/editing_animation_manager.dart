import 'dart:async';

import 'package:rive_core/animation/linear_animation.dart';
import 'package:rxdart/rxdart.dart';

class EditingAnimationManager {
  final LinearAnimation editingAnimation;

  final _fpsController = StreamController<int>();

  final _timeController = StreamController<double>();
  

  EditingAnimationManager(this.editingAnimation) {
    _timeStream.add(0);
  }

  /// Change the current time displayed (value is in seconds).
  Sink<double> get changeCurrentTime => _timeController;
  
  /// Change the fps of the current animation.
  Sink<int> get changeRate => _fpsController;


  final _timeStream = BehaviorSubject<int>();
  ValueStream<int> get currentTime => _timeStream;

  void dispose() {
    _timeController.close();
    _timeStream.close();
    _fpsController.close();
  }
}
