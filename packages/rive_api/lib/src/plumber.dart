import 'package:rxdart/rxdart.dart';
import 'package:rxdart/subjects.dart';

class Plumber {
  Plumber._();
  static Plumber _instance = Plumber._();
  factory Plumber() => _instance;

  final Map<Type, BehaviorSubject> _pipes = {};

  // Retrives the pipe for the given model.
  // Lays it down if not present.
  BehaviorSubject<T> _pipeInit<T>() {
    if (!_pipes.containsKey(T)) {
      print("Lay down the pipes for $T");
      _pipes[T] = BehaviorSubject<T>();
    }
    return _pipes[T];
  }

  ValueStream<T> getStream<T>() {
    var pipe = _pipeInit<T>();
    return pipe.stream;
  }

  void message<T>(T message) {
    var pipe = _pipeInit<T>();
    pipe.add(message);
  }

  void clear<T>() {
    var pipe = _pipeInit<T>();
    pipe.add(null);
  }
}
