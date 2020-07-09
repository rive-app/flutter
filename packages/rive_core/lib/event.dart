import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Just a way to get around the protected notifyListeners so we can use trigger
// multiple events from a single object.
class Event extends ChangeNotifier {
  void notify() => notifyListeners();
}
// -> editor-only
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


/// A ValueNotifier that can optionally suppress notifying when setting values
/// in bulk. Also allows later notifying once bulk operations are complete.
class SuppressableValueNotifier<T> extends ChangeNotifier
    implements ValueListenable<T> {
  /// Creates a [ChangeNotifier] that wraps this value.
  SuppressableValueNotifier(this._value);

  /// The current value stored in this notifier.
  ///
  /// When the value is replaced with something that is not equal to the old
  /// value as evaluated by the equality operator ==, this class notifies its
  /// listeners.
  @override
  T get value => _value;
  T _value;
  set value(T newValue) {
    changeValue(newValue, notify: true);
  }

  void changeValue(T newValue, {bool notify = false}) {
    if (_value == newValue) {
      return;
    }
    _value = newValue;
    if (notify) {
      notifyListeners();
    }
  }

  void notify() => notifyListeners();

  @override
  String toString() => '${describeIdentity(this)}($value)';
}
// <- editor-only