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
