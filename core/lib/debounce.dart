import 'dart:async';

typedef DebounceCallback = void Function();

Map<DebounceCallback, Timer> _debounce = {};
void debounce(DebounceCallback callback,
    {Duration duration = const Duration(milliseconds: 15)}) {
  _debounce[callback] ??= Timer(duration, () {
    _debounce.remove(callback);
    callback();
  });
}

void cancelDebounce(DebounceCallback callback) {
  _debounce[callback]?.cancel();
}

abstract class Debouncer {
  void onNeedsDebounce();
  final Set<DebounceCallback> _debounce = {};
  bool debounce(DebounceCallback call) {
    if (_debounce.add(call)) {
      onNeedsDebounce();
      return true;
    }
    return false;
  }

  bool debounceAll() {
    if (_debounce.isEmpty) {
      return false;
    }
    for (final call in _debounce) {
      call();
    }
    _debounce.clear();
    return true;
  }

  bool cancelDebounce(DebounceCallback call) => _debounce.remove(call);
  bool get needsDebounce => _debounce.isNotEmpty;
}
