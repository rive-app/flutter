import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/runtime/runtime_importer.dart';
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

Future<OpenFileContext> makeFile({bool addArtboard = true}) async {
  var file = TestOpenFileContext();
  expect(await file.fakeConnect(), true);
  if (addArtboard) {
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
  }
  return file;
}

/// Load an OpenFileContext from a runtime .riv file.
Future<OpenFileContext> loadFile(String filename,
    {bool addArtboard = true}) async {
  var file = await makeFile(addArtboard: false);
  var bytes = await File(filename).readAsBytes();
  var importer = RuntimeImporter(core: file.core);
  if (importer.import(bytes)) {
    file.core.captureJournalEntry();
    return file;
  }
  return null;
}
