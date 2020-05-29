import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Event extends ChangeNotifier {
  void notify() => notifyListeners();
}

abstract class DetailListenable<T> {
  bool addListener(void Function(T) callback);
  bool removeListener(void Function(T) callback);
}

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
    var listeners = _listeners.toList(growable: false);
    for (final listener in listeners) {
      listener(details);
    }
  }
}
