import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:core/debounce.dart';
import 'package:utilities/binary_buffer/binary_reader.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';
import 'package:core/coop/change.dart';
import 'package:core/coop/coop_command.dart';
import 'package:core/coop/coop_isolate.dart';
import 'package:core/coop/coop_server.dart';
import 'package:core/coop/coop_server_client.dart';
import 'package:core/core.dart';

import 'package:core/coop/coop_file.dart';
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
  void heartbeat([Map<String, String> data]) => PrivateApi().heartbeat(data);

  static Future<void> makeProcess(CoopIsolateArgument argument) async {
    var process = RiveCoopIsolateProcess();
    await process.initProcess(
        argument.sendPort, argument.options, argument.fileId);
  }
}

class RiveCoopIsolateProcess extends CoopIsolateProcess {
  CoopFile file;
  int _nextChangeId;
  final PrivateApi _privateApi;

  // We store the fileId on the isolate process just incase the one in
  // the file/revision-data is out of sync or someone sneakily copied the
  // revision data (to do testing like Luigi ran into) from another file. This
  // ensures that the coop server is writing to the file it was given as an id
  // to connect to. N.B. this'll need to update when we move to single id (maybe
  // it'll just be a string).
  int _fileId;

  RiveCoopIsolateProcess({String privateApiHost})
      : _privateApi = PrivateApi(host: privateApiHost);

  @override
  bool attemptChange(CoopServerClient client, ChangeSet changeSet) {
    print(
        'attemptChange for client ${client.id}: id(${changeSet.id}) objects(${changeSet.objects.length}) propertyChanges(${changeSet.numProperties})');
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
    bool isChangeValid = true;

    objectChangesLoop:
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
              serverLog('reject due to duplicate objectId: $objectId');
              isChangeValid = false;
              break objectChangesLoop;
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
              prop.data = Uint8List.fromList(change.value);
              break;
          }
        }
      }
    }
    if (isChangeValid && validateDependencies) {
      if (modifiedFile.hasCyclicDependencies()) {
        serverLog('reject due to dependency cycle');
        isChangeValid = false;
      }
    }

    print('will persist change set');
    // Decide if we want to save the changeset (in the future we could make this
    // depend on whether some flag is enabled for this
    // user/owner/file/whatever). For now save em all.
    _privateApi.persistChangeSet(
        client, file, serverChangeId, changeSet, isChangeValid);

    if (isChangeValid) {
      print('change is valid ${changeSet.id}');
      // Changes were good, modify file and propagate them to other clients.
      file = modifiedFile;
      propagateChanges(client, serverChangeSet);
      return true;
    } else {
      print('change is rejected');
      // do not change the file, reject the change.
      return false;
    }
  }

  @override
  ChangeSet buildFileChangeSet() {
    print('building changeSet from file to send to client on initial connect');
    var changeSet = file.toChangeSet();
    print('change set details: objects(${changeSet.objects.length}) '
        'numProperties(${changeSet.numProperties})');
    return changeSet;
  }

  void serverLog(String message) {
    print('coop file: ${file?.fileId} - $message');
  }

  @override
  Future<bool> initialize(int fileId, Map<String, String> options) async {
    _fileId = fileId;
    // check data is not null, check signature, if it's RIVE deserialize
    // if it's { or something else, send wtf.
    var data = await _privateApi.load(fileId);
    if (data == null) {
      print('failed to load revision from private_api $fileId');
      // private api is currently not availble or somehow failed, make sure we
      // terminate the connect (client will retry).
      return false;
    }

    print('revision data is ${data.length} bytes $fileId');
    if ((data.isNotEmpty && data[0] == '{'.codeUnitAt(0)) ||
        (data == null || data.isEmpty)) {
      print('bad data in revision for $fileId, making empty file');
      file = CoopFile()
        ..fileId = fileId
        ..objects = {};
    } else {
      print('attempting to deserialize');
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
        print('failed to deserialize revision for $fileId');
        try {
          var stringData = utf8.decode(data, allowMalformed: true);
          print('failed data looks like $stringData');
        } on Error {
          print('failed to decode ${data.length} $data');
        }
        file = CoopFile()
          ..fileId = fileId
          ..objects = {};
      } else {
        print('deserialized');
      }
    }
    _nextChangeId = max(file.serverChangeId, CoopCommand.minChangeId) + 1;
    print('next change id is $_nextChangeId');
    return true;
  }

  @override
  void propagateChanges(CoopServerClient client, ChangeSet changes) {
    var writer = BinaryWriter();
    changes.serialize(writer);
    // TODO: consider changing this to readyClients as clients that are
    // connecting/sending offline changes should not receive mid-flight changes
    // prior to their ready.
    // print("PROPAGATING TO ${clients.length} CLIENTS");
    for (final to in clients) {
      // don't send to self
      if (client == to) {
        continue;
      }
      to.write(writer.uint8Buffer);
    }
  }

  Completer _persistCompleter;
  @override
  Future<void> persist() async {
    var completer = Completer<void>();
    _persistCompleter = completer;
    var writer = BinaryWriter(alignment: max(1, file.objects.length) * 256);
    file.serialize(writer);
    await _privateApi.save(_fileId, writer.uint8Buffer);
    completer.complete();
  }

  @override
  Future<bool> shutdown() async {
    // If a persist call was debounced, force it to happen now and await its
    // completer.
    if (debounceAccelerate(persist)) {
      if (_persistCompleter?.future != null) {
        await _persistCompleter.future;
      }
    }
    return true;
  }

  @override
  int nextClientId() {
    return file.nextClientId++;
  }

  @override
  Future<void> restoreRevision(int revisionId) async {
    for (final to in clients) {
      to.notifyChangingRevision();
    }
    var data = await _privateApi.restoreRevision(_fileId, revisionId);
    if (data == null) {
      print('no data from restore?');
      return;
    }
    var coopFile = CoopFile();
    if (coopFile.deserialize(BinaryReader.fromList(data))) {
      file = coopFile;

      for (final to in clients) {
        to.completeChangingRevision();
      }
    }
  }
}
