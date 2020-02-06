import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:binary_buffer/binary_reader.dart';
import 'package:binary_buffer/binary_writer.dart';
import 'package:core/coop/change.dart';
import 'package:core/coop/coop_isolate.dart';
import 'package:core/coop/coop_server.dart';
import 'package:core/coop/coop_server_client.dart';
import 'package:core/core.dart';

import 'src/coop_file.dart';
import 'src/private_api.dart';

class RiveCoopServer extends CoopServer {
  @override
  CoopIsolateHandler get handler => makeProcess;

  @override
  Future<int> validate(
      HttpRequest request, int ownerId, int fileId, String token) async {
    var api = PrivateApi();
    var validationResult = await api.validate(ownerId, fileId, token);
    return validationResult.ownerId;
  }

  static Future<void> makeProcess(CoopIsolateArgument argument) async {
    var process = _CoopIsolate();
    var success = await process.initProcess(
        argument.sendPort, argument.options, argument.ownerId, argument.fileId);
    if (success) {
      // ok, anything to do?
    }
  }
}

class _CoopIsolate extends CoopIsolateProcess {
  CoopFile file;
  int _nextObjectId;
  int _nextChangeId;
  final _privateApi = PrivateApi();

  @override
  int attemptChange(CoopServerClient client, ChangeSet changeSet) {
    // Make the change on a clone.
    var modifiedFile = file.clone();
    var serverChangeId = _nextChangeId++;
    var serverChangeSet = ChangeSet()
      ..id = serverChangeId
      ..objects = [];
    bool validateDependencies = false;
    for (final objectChanges in changeSet.objects) {
      // print("CHANGING ${objectChanges.objectId}");

      // Don't propagate changes to dependent ids. Clients build these up and
      // send them to the server for validating concurrent changes, there's no
      // need to send them to other clients.
      var serverChange = objectChanges
          .clone((change) => change.op != CoreContext.dependentsKey);

      serverChangeSet.objects.add(serverChange);

      // Transform object id if necessary (was an object that got created).
      serverChange.objectId =
          client.changedIds[objectChanges.objectId] ?? objectChanges.objectId;
      CoopFileObject object = modifiedFile.objects[serverChange.objectId];

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
            var nextId = _nextObjectId++;
            serverChange.objectId = nextId;
            print("ADDING SERVER OBJECT WITH ID ${serverChange.objectId}");
            modifiedFile.objects[nextId] = object = CoopFileObject()
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
            object = modifiedFile.objects.remove(objectId);

            print("DESTROY OBJECT ${objectChanges.objectId} ${change.value}");
            // Destroy object with id
            break;
          default:
            break;
        }
      }

      // now actually make changes to the object (if we have one).
      if (object != null) {
        object.serverChangeId = serverChangeId;
        object.userId = client.userOwnerId;
        for (final change in objectChanges.changes) {
          switch (change.op) {
            case CoreContext.addKey:
              // Handled previously
              break;
            case CoreContext.removeKey:
              // Handled previously
              break;
            case CoreContext.dependentsKey:
              // need to re-validate dependencies as the dependents have
              // changed.
              validateDependencies = true;
              continue general;
            general:
            default:
              var prop = object.properties[change.op] ??= ObjectProperty();
              prop.key = change.op;
              prop.serverChangeId = serverChangeId;
              prop.userId = client.userOwnerId;
              prop.data = change.value;
              break;
          }
        }
      }
    }

    bool isChangeValid = true;
    if (validateDependencies) {}

    if (isChangeValid) {
      // Changes were good, modify file and propagate them to other clients.
      file = modifiedFile;
      print("CHANGE ID ${serverChangeSet.id}");
      propagateChanges(client, serverChangeSet);
      return serverChangeSet.id;
    } else {
      // do not change the file, reject the change.
      return 0;
    }
  }

  @override
  ChangeSet initialChanges() {
    return file.toChangeSet();
  }

  @override
  Future<bool> initialize(
      int ownerId, int fileId, Map<String, String> options) async {
    // check data is not null, check signature, if it's RIVE deserialize
    // if it's { or something else, send wtf.

    // TODO: get the file from some source (S3?). For now we just instance a new
    // file.
    var data = await _privateApi.load(ownerId, fileId);

    if ((data.isNotEmpty && data[0] == '{'.codeUnitAt(0)) ||
        (data == null || data.isEmpty)) {
      _nextObjectId = 1;
      _nextChangeId = 1;

      file = CoopFile()
        ..ownerId = ownerId
        ..fileId = fileId
        ..objects = {};
    } else {
      file = CoopFile()
        ..deserialize(
          BinaryReader(
            ByteData.view(
              data.buffer,
              data.offsetInBytes,
              data.lengthInBytes,
            ),
          ),
        );

      _nextObjectId = file.objects.values
              .fold<int>(0, (curr, object) => max(curr, object.localId)) +
          1;

      _nextChangeId = file.objects.values.fold<int>(
              0, (curr, object) => max(curr, object.serverChangeId)) +
          1;
    }
    return true;
  }

  @override
  void propagateChanges(CoopServerClient client, ChangeSet changes) {
    var writer = BinaryWriter();
    changes.serialize(writer);
    // TODO: consider changing this to readyClients as clients that are
    // connecting/sending offline changes should not receive mid-flight changes
    // prior to their ready.
    for (final to in clients) {
      to.write(writer.uint8Buffer);
    }
  }

  @override
  Future<void> persist() async {
    var writer = BinaryWriter(alignment: file.objects.length * 256);
    file.serialize(writer);
    print("PERSISTING! ${writer.uint8Buffer} ${file.ownerId} ${file.fileId}");
    var result =
        await _privateApi.save(file.ownerId, file.fileId, writer.uint8Buffer);
    print("GOT REVISION ID ${result.revisionId}");
  }

  @override
  Future<bool> shutdown() async {
    // TODO: Make sure debounced save has completed.
    return true;
  }
}
