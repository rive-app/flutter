import 'package:rive_api/src/view_model/view_model.dart';
import 'package:rxdart/rxdart.dart';
import 'package:rxdart/subjects.dart';

class Plumber {
  Plumber._();
  static Plumber _instance = Plumber._();
  factory Plumber() => _instance;

  final Map<Type, BehaviorSubject<ViewModel>> _pipes = {};

  // Retrives the pipe for the given model.
  // Lays it down if not present.
  BehaviorSubject<T> _pipeInit<T extends ViewModel>() {
    if (!_pipes.containsKey(T)) {
      print("Lay down the pipes for $T");
      _pipes[T] = BehaviorSubject<T>();
    }
    return _pipes[T];
  }

  ValueStream<T> getStream<T extends ViewModel>() {
    var pipe = _pipeInit<T>();
    return pipe.stream;
  }

  void message<T extends ViewModel>(T message) {
    var pipe = _pipeInit<T>();
    pipe.add(message);
  }
}
