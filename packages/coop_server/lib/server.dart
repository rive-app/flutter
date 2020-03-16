import 'dart:math';
import 'dart:typed_data';

import 'package:binary_buffer/binary_reader.dart';
import 'package:binary_buffer/binary_writer.dart';
import 'package:core/coop/change.dart';
import 'package:core/coop/coop_command.dart';
import 'package:core/coop/coop_isolate.dart';
import 'package:core/coop/coop_server.dart';
import 'package:core/coop/coop_server_client.dart';
import 'package:core/core.dart';

import 'src/coop_file.dart';
import 'src/private_api.dart';

class RiveCoopServer extends CoopServer {
  @override
  CoopIsolateHandler get handler => makeProcess;

  /// Registers the co-op server with the 2D service
  /// Returns true if it successfully registers
  @override
  Future<bool> register() async => PrivateApi().register();

  /// Deregisteres the co-op server from the 2D service
  @override
  Future<bool> deregister() async => PrivateApi().deregister();

  /// Pings the 2D service heartbeat endpoint
  @override
  void heartbeat() => PrivateApi().heartbeat();

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
  int _nextChangeId;
  final _privateApi = PrivateApi();

  @override
  bool attemptChange(CoopServerClient client, ChangeSet changeSet) {
    // Make the change on a clone.
    var modifiedFile = file.clone();
    // One thing to note is that the following will increment
    /// even if the change is rejected. That's probably ok for now.
    /// We need to evaluate at some point if we even need this
    /// serverChangeId at all (got to check what we're doing with it
    /// on the client).
    var serverChangeId = _nextChangeId++;
    modifiedFile.serverChangeId = serverChangeId;
    var serverChangeSet = ChangeSet()
      ..id = serverChangeId
      ..objects = [];
    bool validateDependencies = false;
    for (final clientObjectChanges in changeSet.objects) {
      // print("CHANGING ${objectChanges.objectId}");

      // Don't propagate changes to dependent ids. Clients build these up and
      // send them to the server for validating concurrent changes, there's no
      // need to send them to other clients.
      var serverChange = clientObjectChanges
          .clone((change) => change.op != CoreContext.dependentsKey);

      serverChangeSet.objects.add(serverChange);

      CoopFileObject object = modifiedFile.objects[serverChange.objectId];

      for (final change in clientObjectChanges.changes) {
        switch (change.op) {
          case CoreContext.addKey:
            // id is clientObjectChanges.objectId

            var reader = BinaryReader(
              ByteData.view(
                change.value.buffer,
                change.value.offsetInBytes,
                change.value.length,
              ),
            );

            var objectId = clientObjectChanges.objectId;

            // Does an object with this id already exist? Abort!
            if (modifiedFile.objects.containsKey(objectId)) {
              return false;
            }
            modifiedFile.objects[objectId] = object = CoopFileObject()
              ..objectId = objectId
              ..key = reader.readVarUint();
            break;
          case CoreContext.removeKey:
            var objectId = clientObjectChanges.objectId;
            object = modifiedFile.objects.remove(objectId);
            // Destroy object with id
            break;
          default:
            break;
        }
      }

      // now actually make changes to the object (if we have one).
      if (object != null) {
        for (final change in clientObjectChanges.changes) {
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
              prop.data = change.value;
              break;
          }
        }
      }
    }

    bool isChangeValid = true;
    if (validateDependencies) {
      // TODO: do the validation
    }

    if (isChangeValid) {
      // Changes were good, modify file and propagate them to other clients.
      file = modifiedFile;
      print("CHANGE ID ${serverChangeSet.id}");
      propagateChanges(client, serverChangeSet);
      return true;
    } else {
      // do not change the file, reject the change.
      return false;
    }
  }

  @override
  ChangeSet buildFileChangeSet() {
    return file.toChangeSet();
  }

  @override
  Future<bool> initialize(
      int ownerId, int fileId, Map<String, String> options) async {
    // check data is not null, check signature, if it's RIVE deserialize
    // if it's { or something else, send wtf.
    var data = await _privateApi.load(ownerId, fileId);

    if ((data.isNotEmpty && data[0] == '{'.codeUnitAt(0)) ||
        (data == null || data.isEmpty)) {
      file = CoopFile()
        ..ownerId = ownerId
        ..fileId = fileId
        ..objects = {};
    } else {
      file = CoopFile();
      if (!file.deserialize(
        BinaryReader(
          ByteData.view(
            data.buffer,
            data.offsetInBytes,
            data.lengthInBytes,
          ),
        ),
      )) {
        file = CoopFile()
          ..ownerId = ownerId
          ..fileId = fileId
          ..objects = {};
      }
    }
    _nextChangeId = max(file.serverChangeId, CoopCommand.minChangeId) + 1;
    return true;
  }

  @override
  void propagateChanges(CoopServerClient client, ChangeSet changes) {
    var writer = BinaryWriter();
    changes.serialize(writer);
    // TODO: consider changing this to readyClients as clients that are
    // connecting/sending offline changes should not receive mid-flight changes
    // prior to their ready.
    print("PROPAGATING TO ${clients.length} CLIENTS");
    for (final to in clients) {
      to.write(writer.uint8Buffer);
    }
  }

  @override
  Future<void> persist() async {
    var writer = BinaryWriter(alignment: max(1, file.objects.length) * 256);
    file.serialize(writer);
    var result =
        await _privateApi.save(file.ownerId, file.fileId, writer.uint8Buffer);
    print("GOT REVISION ID ${result.revisionId}");
  }

  @override
  Future<bool> shutdown() async {
    // TODO: Make sure debounced save has completed.
    return true;
  }

  @override
  int nextClientId() {
    return file.nextClientId++;
  }
}
