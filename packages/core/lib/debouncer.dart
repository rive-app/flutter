import 'package:core/debounce.dart';

/// A scoped debouncer that must specifically call when to debounce
abstract class Debouncer {
  void onNeedsDebounce();
  final Map<DebounceCallback, DateTime> _debounce = {};

  /// Call to debounce to ensure high frequency events get processed only once.
  /// Set [reset] to true to keep debouncing as events keep coming in. Set
  /// [reset] to false to ensure compute happens every [duration].
  bool debounce(
    DebounceCallback call, {
    Duration duration = Duration.zero,
    bool reset = false,
  }) {
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

  bool debounceAll({bool force = false}) {
    if (_debounce.isEmpty) {
      return false;
    }

    var remove = <DebounceCallback>[];
    var now = DateTime.now();
    _debounce.forEach((key, value) {
      if (force || value.isBefore(now)) {
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
