import 'dart:io';
import 'dart:typed_data';
import 'package:binary_buffer/binary_reader.dart';
import 'package:binary_buffer/binary_writer.dart';
import 'package:core/coop/change.dart';
import 'package:core/coop/coop_command.dart';
import 'package:core/coop/coop_server.dart';
import 'package:core/coop/coop_server_client.dart';
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
      ..objects = {};
    fileMeta = CoopFileServerData()
      ..sessions = []
      ..nextChangeId = CoopCommand.minChangeId
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
  bool attemptChange(CoopServerClient client, ChangeSet changeSet) {
    var serverChangeSet = ChangeSet()
      ..id = fileMeta.nextChangeId++
      ..objects = [];
    for (final objectChanges in changeSet.objects) {
      print("CHANGING ${objectChanges.objectId}");
      var serverChange = objectChanges.clone();
      serverChangeSet.objects.add(serverChange);
      for (final change in objectChanges.changes) {
        switch (change.op) {
          case CoreContext.addKey:
            // id is change.objectId

            var reader = BinaryReader(
              ByteData.view(
                change.value.buffer,
                change.value.offsetInBytes,
                change.value.length,
              ),
            );

            // TODO: need to upgrade the object id to a global/server one.
            var nextId = fileMeta.nextObjectId++;
            serverChange.objectId = nextId;
            print("ADDING SERVER OBJECT WITH ID ${serverChange.objectId}");
            file.objects[nextId] = CoopFileObject()
              ..localId = nextId
              ..key = reader.readVarUint();
            client.changedIds[objectChanges.objectId] = nextId;
            client.writer.writeChangeId(objectChanges.objectId, nextId);
            print("MAKE OBJECT ${objectChanges.objectId} ${change.value}");
            // create object with id
            break;
          case CoreContext.removeKey:
            var objectId = client.changedIds[objectChanges.objectId] ??
                objectChanges.objectId;
            file.objects.remove(objectId);
            print("DESTROY OBJECT ${objectChanges.objectId} ${change.value}");
            // Destroy object with id
            break;
          default:
            // Transform object id if necessary (was an object that got created).
            var objectId = client.changedIds[objectChanges.objectId] ??
                objectChanges.objectId;
            serverChange.objectId = objectId;
            break;
        }
      }
    }
    print("CHANGE ID ${serverChangeSet.id}");
    propagateChanges(client, serverChangeSet);
    return true;
  }

  @override
  void propagateChanges(CoopServerClient client, ChangeSet changes) {
    var writer = BinaryWriter();
    changes.serialize(writer);
    for (final to in clients) {
      if (to == client) {
        continue;
      }
      to.write(writer.uint8Buffer);
    }
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
