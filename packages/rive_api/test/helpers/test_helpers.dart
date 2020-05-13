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
    expect(checks.length == 0, false,
        reason: 'More unexpected data coming in for $T');
    var check = checks.removeAt(0);
    expect(check(streamData), true,
        reason: 'Check $checkNumber failed for $T with data $streamData');

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
