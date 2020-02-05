import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:core/coop/change.dart';
import 'package:core/coop/coop_server_client.dart';
import 'package:core/coop/coop_server.dart';
import 'package:core/coop/coop_user.dart';
import 'package:rive_core/data_directory.dart';
import 'package:core/coop/coop_isolate.dart';

class _TestCoopIsolate extends CoopIsolateProcess {
  Directory _dataDir;
  int ownerId;
  int fileId;

  @override
  Future<bool> initialize(int ownerId, int fileId,
      [Map<String, String> options]) async {
    this.ownerId = ownerId;
    this.fileId = fileId;
    _dataDir = await dataDirectory("test_coop_server");
    return _dataDir != null;
  }

  @override
  Future<Uint8List> loadData(String key) async {
    print("WRITING TO KEY $key ${_dataDir.path + key}");
    var file = File(_dataDir.path + key);
    return file.readAsBytes();
  }

  @override
  Future<bool> saveData(String key, Uint8List data) async {
    var file = File(_dataDir.path + key);
    await file.writeAsBytes(data, flush: true);
    return true;
  }

  @override
  Future<bool> shutdown() async {
    await _dataDir.delete(recursive: true);
    return true;
  }

  @override
  Future<CoopUser> login(String token) async {
    // In test mode we validate any user...
    return CoopUser(1);
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
  ChangeSet initialChanges() {
    // TODO: implement initialChanges
    return null;
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
  Future<bool> validate(HttpRequest request, int ownerId, int fileId) async {
    return true;
  }
}
