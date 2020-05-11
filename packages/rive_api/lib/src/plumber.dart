import 'package:rxdart/rxdart.dart';
import 'package:rxdart/subjects.dart';

class Plumber {
  Plumber._();
  static Plumber _instance = Plumber._();
  factory Plumber() => _instance;

  final Map<Type, Map<String, BehaviorSubject>> _pipes = {};

  // Retrives the pipe for the given model.
  // Lays it down if not present.
  BehaviorSubject<T> _pipeInit<T>([String id]) {
    if (!_pipes.containsKey(T)) {
      _pipes[T] = {};
    }
    if (!_pipes[T].containsKey(id)) {
      print("Lay down the pipes for $T:$id");
      _pipes[T][id] = BehaviorSubject<T>();
    }
    return _pipes[T][id];
  }

  ValueStream<T> getStream<T>([String id]) {
    var pipe = _pipeInit<T>(id);
    return pipe.stream;
  }

  void message<T>(T message, [String id]) {
    var pipe = _pipeInit<T>(id);
    pipe.add(message);
  }

  void clear<T>([String id]) {
    var pipe = _pipeInit<T>(id);
    if (pipe.value != null) {
      pipe.add(null);
    }
  }

  void reset() {
    // TODO: notify a few thigns to disconnect from each other?
    _pipes.values.forEach((pipeMap) {
      pipeMap.values.forEach((pipe) {
        pipe.close();
      });
    });
    _pipes.clear();
  }
}
