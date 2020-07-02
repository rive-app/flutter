import 'package:core/debounce.dart';

/// A scoped debouncer that must specifically call when to debounce
abstract class Debouncer {
  void onNeedsDebounce();
  final Map<DebounceCallback, DateTime> _debounce = {};
  bool debounce(DebounceCallback call, {Duration duration = Duration.zero}) {
    if (_debounce.containsKey(call)) {
      return false;
    }
    _debounce[call] = DateTime.now().add(duration);
    onNeedsDebounce();
    return true;
  }

  /// Call early if it's queued.
  bool debounceAccelerate(DebounceCallback call) {
    if (_debounce.containsKey(call)) {
      _debounce.remove(call);
      call();
      return true;
    }
    return false;
  }

  bool debounceAll() {
    if (_debounce.isEmpty) {
      return false;
    }

    var remove = <DebounceCallback>[];
    var now = DateTime.now();
    _debounce.forEach((key, value) {
      if (value.isBefore(now)) {
        remove.add(key);
      }
    });

    remove.forEach(_debounce.remove);

    for (final call in remove) {
      call();
    }

    return true;
  }

  bool cancelDebounce(DebounceCallback call) => _debounce.remove(call) != null;
  bool get needsDebounce => _debounce.isNotEmpty;
}
