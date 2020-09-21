import 'dart:async';

typedef DebounceCallback = void Function();

Map<DebounceCallback, Timer> _debounce = {};
DebounceCallback debounce(DebounceCallback callback,
    {Duration duration = const Duration(milliseconds: 15)}) {
  _debounce[callback] ??= Timer(duration, () {
    _debounce.remove(callback);
    callback();
  });
  return callback;
}

bool debounceAccelerate(DebounceCallback call) {
  if (_debounce.containsKey(call)) {
    _debounce.remove(call);
    call();
    return true;
  }
  return false;
}

void cancelDebounce(DebounceCallback callback) {
  _debounce[callback]?.cancel();
}
