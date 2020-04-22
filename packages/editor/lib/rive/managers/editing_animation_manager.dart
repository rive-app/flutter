import 'dart:async';

import 'package:rive_core/animation/linear_animation.dart';
import 'package:rxdart/rxdart.dart';

class EditingAnimationManager {
  final LinearAnimation editingAnimation;

  final _durationController = StreamController<int>();
  final _fpsController = StreamController<int>();

  final _timeStream = BehaviorSubject<int>();
  final _timeController = StreamController<int>();
  final _timeCodeStream = BehaviorSubject<String>();
  

  EditingAnimationManager(this.editingAnimation) {
    editingAnimation.addListener(
        LinearAnimationBase.fpsPropertyKey, _fpsChanged);
    _timeStream.add(0);
  }

  void _fpsChanged(dynamic from, dynamic to) {
    _updateTimeCode();
  }

  void _updateTimeCode() {
    _timeCodeStream.add('');
  }

  Sink<int> get changeCurrentTime => _timeController;
  Stream<int> get currentTime => _timeStream;

  void dispose() {
    editingAnimation.removeListener(
        LinearAnimationBase.fpsPropertyKey, _fpsChanged);
    _durationController.close();
    _timeController.close();
    _timeStream.close();
    _fpsController.close();
  }
}
