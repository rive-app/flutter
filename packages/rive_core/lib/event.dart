import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Just a way to get around the protected notifyListeners so we can use trigger
// multiple events from a single object.
class Event extends ChangeNotifier {
  void notify() => notifyListeners();
}

/// A listenable with details of type [T].
abstract class DetailListenable<T> {
  bool addListener(void Function(T) callback);

  bool removeListener(void Function(T) callback);
}

/// An event with an argument of [T].
class DetailedEvent<T> implements DetailListenable<T> {
  final HashSet<void Function(T)> _listeners = HashSet<void Function(T)>();
  @override
  bool addListener(void Function(T) callback) {
    assert(callback != null, 'no null listener callbacks');
    return _listeners.add(callback);
  }

  @override
  bool removeListener(void Function(T) callback) {
    assert(callback != null, 'no null listener callbacks');
    return _listeners.remove(callback);
  }

  void notify(T details) {
    // clone in case it is modified during iteration.
    var listeners = _listeners.toList(growable: false);
    for (final listener in listeners) {
      listener(details);
    }
  }
}
