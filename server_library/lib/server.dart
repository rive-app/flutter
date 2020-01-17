import 'dart:io';
import 'dart:typed_data';

import 'package:core/coop/change.dart';
import 'package:core/coop/coop_server.dart';
import 'package:core/coop/coop_user.dart';
import 'package:core/coop/coop_session.dart';
import 'package:core/coop/coop_isolate.dart';
import 'package:core/core.dart';

import 'src/coop_file.dart';

class _CoopIsolate extends CoopIsolateProcess {
  CoopFile file;
  CoopFileServerData fileMeta;

  Directory _dataDir;
  @override
  Future<bool> initialize(
      int ownerId, int fileId, Map<String, String> options) async {
    _dataDir = Directory(options['data-dir']);

    // TODO: get the file from some source (S3?). For now we just instance a new
    // file.
    file = CoopFile()
      ..ownerId = ownerId
      ..fileId = ownerId
      ..objects = [];
    fileMeta = CoopFileServerData()
      ..sessions = []
      ..nextChangeId = 1
      ..nextObjectId = 1;

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
  Future<CoopSession> login(String token, int desiredSession) async {
    // In test mode we validate any user...
    return CoopSession()
      ..id = desiredSession
      ..changeId = 2
      ..user = CoopUser(1);
  }

  @override
  bool attemptChange(ChangeSet changes) {
    for (final change in changes.changes) {
      switch (change.op) {
        case CoreContext.addKey:
        // id is change.objectId
          print("MAKE OBJECT ${change.objectId} ${change.value}");
          // create object with id
          break;
        case CoreContext.removeKey:
          print("DESTROY OBJECT ${change.objectId} ${change.value}");
          // Destroy object with id
          break;
      }
    }
    return true;
  }
}

class RiveCoopServer extends CoopServer {
  @override
  CoopIsolateHandler get handler => makeProcess;

  static Future<void> makeProcess(CoopIsolateArgument argument) async {
    var process = _CoopIsolate();
    var success = await process.initProcess(
        argument.sendPort, argument.options, argument.ownerId, argument.fileId);
    if (success) {
      // ok, anything to do?
    }
  }

  @override
  Future<bool> validate(HttpRequest request, int ownerId, int fileId) async {
    return true;
  }
}
