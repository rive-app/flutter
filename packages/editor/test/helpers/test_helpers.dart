import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_editor/rive/open_file_context.dart';

import 'test_open_file_context.dart';

Completer testStream<T>(
  Stream<T> stream,
  List<Function(T)> checks, [
  Function callback,
]) {
  final completer = Completer<dynamic>();
  int checkNumber = 1;
  stream.listen((streamData) {
    expect(checks.isEmpty, false,
        reason: 'More unexpected data coming in for $T');
    var check = checks.removeAt(0);
    expect(check(streamData), true,
        reason: 'Check $checkNumber failed for $T with data $streamData');

    if (checks.isEmpty) {
      completer.complete();
      if (callback != null) {
        callback();
      }
    }
    checkNumber += 1;
  });
  return completer;
}

Future<OpenFileContext> makeFile() async {
  var file = TestOpenFileContext();
  expect(await file.fakeConnect(), true);
  Artboard artboard;
  final core = file.core;
  core.batchAdd(() {
    artboard = Artboard()
      ..name = 'My Artboard'
      ..x = 0
      ..y = 0
      ..width = 1920
      ..height = 1080;

    core.addObject(artboard);
  });
  core.captureJournalEntry();
  return file;
}
