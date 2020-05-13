import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

Completer testStream<T>(
  Stream<T> stream,
  List<Function(T)> checks, [
  Function callback,
]) {
  final completer = Completer();
  int checkNumber = 1;
  stream.listen((streamData) {
    print('DATA: $streamData');
    var check = checks.removeAt(0);
    expect(check(streamData), true, reason: 'Check $checkNumber failed for $T');

    if (checks.length == 0) {
      completer.complete();
      if (callback != null) {
        callback();
      }
    }
    checkNumber += 1;
  });
  return completer;
}
