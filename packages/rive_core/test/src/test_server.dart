import 'dart:io';
import 'dart:typed_data';

import 'package:core/coop/change.dart';
import 'package:core/coop/coop_server_client.dart';
import 'package:core/coop/coop_server.dart';
import 'package:core/coop/coop_isolate.dart';

class _TestCoopIsolate extends CoopIsolateProcess {
  Directory _dataDir;
  int ownerId;
  int fileId;
  int _nextClientId = 0;

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
  Future<bool> shutdown() async => true;

  @override
  bool attemptChange(CoopServerClient client, ChangeSet changes) => true;

  @override
  void propagateChanges(CoopServerClient client, ChangeSet changes) {}

  @override
  ChangeSet buildFileChangeSet() {
    return null;
  }

  @override
  Future<void> persist() {
    return Future<void>.value();
  }

  @override
  int nextClientId() => _nextClientId++;
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
    return Future.value(1);
  }

  @override
  Future<bool> deregister() {
    throw UnimplementedError();
  }

  @override
  void heartbeat() {}

  @override
  Future<bool> register() {
    throw UnimplementedError();
  }
}

/// Manually test that the test server can be started
Future main() async {
  final server = TestCoopServer();
  print('Listening on port 8124');
  await server.listen(port: 8124);
}
