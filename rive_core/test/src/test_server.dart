import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:core/coop/change.dart';
import 'package:core/coop/coop_server_client.dart';
import 'package:core/coop/coop_server.dart';
import 'package:rive_core/data_directory.dart';
import 'package:core/coop/coop_isolate.dart';

class _TestCoopIsolate extends CoopIsolateProcess {
  Directory _dataDir;
  int ownerId;
  int fileId;

  @override
  Future<bool> initialize(int ownerId, int fileId,
      [Map<String, String> options]) async {
    //this.ownerId = ownerId;
    //this.fileId = fileId;
    return true;
  }

  Future<Uint8List> loadData(String key) async {
    var file = File(_dataDir.path + key);
    return file.readAsBytes();
  }

  Future<bool> saveData(String key, Uint8List data) async {
    var file = File(_dataDir.path + key);
    await file.writeAsBytes(data, flush: true);
    return true;
  }

  @override
  Future<bool> shutdown() async {
    return true;
  }

  @override
  int attemptChange(CoopServerClient client, ChangeSet changes) {
    // return server change id
    return 1;
  }

  @override
  void propagateChanges(CoopServerClient client, ChangeSet changes) {
    // TODO: implement
  }

  @override
  ChangeSet buildFileChangeSet() {
    // TODO: implement initialChanges
    return null;
  }

  @override
  Future<void> persist() {
    // TODO: implement persist
    return Future<void>.value();
  }
}

class TestCoopServer extends CoopServer {
  @override
  CoopIsolateHandler get handler => makeProcess;

  static void makeProcess(CoopIsolateArgument argument) {
    var process = _TestCoopIsolate();
    process.initProcess(
        argument.sendPort, argument.options, process.ownerId, process.fileId);
  }

  @override
  Future<int> validate(
      HttpRequest request, int ownerId, int fileId, String token) {
    // TODO: implement validate
    return Future.value(1);
  }
}
