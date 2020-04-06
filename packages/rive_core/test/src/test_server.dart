import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:core/coop/change.dart';
import 'package:core/coop/coop_command.dart';
import 'package:core/coop/coop_server_client.dart';
import 'package:utilities/binary_buffer/binary_reader.dart';
import 'package:core/coop/coop_server.dart';
import 'package:core/coop/coop_isolate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coop_server_library/server.dart';

class _TestCoopIsolateProcess extends RiveCoopIsolateProcess {
  Directory _dataDir;
  // int ownerId;
  // int fileId;
  // int _nextClientId = 0;

  // @override
  // Future<bool> initialize(int ownerId, int fileId,
  //     [Map<String, String> options]) async {
  //   //this.ownerId = ownerId;
  //   //this.fileId = fileId;
  //   return true;
  // }

  // Future<Uint8List> loadData(String key) async {
  //   var file = File(_dataDir.path + key);
  //   return file.readAsBytes();
  // }

  // Future<bool> saveData(String key, Uint8List data) async {
  //   var file = File(_dataDir.path + key);
  //   await file.writeAsBytes(data, flush: true);
  //   return true;
  // }

  // @override
  // Future<bool> shutdown() async => true;

  // @override
  // bool attemptChange(CoopServerClient client, ChangeSet changes) => true;

  // @override
  // void propagateChanges(CoopServerClient client, ChangeSet changes) {}

  // @override
  // ChangeSet buildFileChangeSet() {
  //   return null;
  // }

  // @override
  // Future<void> persist() {
  //   return Future<void>.value();
  // }

  // @override
  // int nextClientId() => _nextClientId++;
}

class TestCoopIsolate extends CoopIsolate {
  final List<dynamic> _isolateQueue = <dynamic>[];

  TestCoopIsolate(CoopServer server, int ownerId, int fileId)
      : super(server, ownerId, fileId);

  bool _manualDrive = false;
  bool get manualDrive => _manualDrive;
  set manualDrive(bool inManual) {
    if (inManual == _manualDrive) {
      return;
    }
    _manualDrive = inManual;
    if (!inManual) {
      /// Send any remaining queued commands to the isolate since we're back in
      /// autopilot.
      _isolateQueue.forEach(super.sendToIsolate);
      _isolateQueue.clear();
    }
  }

  Completer<dynamic> _nextDataReceived;

  Future<dynamic> processNextCommand() async {
    if (_isolateQueue.isEmpty) {
      _nextDataReceived = Completer<dynamic>();
      return _nextDataReceived.future;
    }

    dynamic first = _isolateQueue.removeAt(0);

    super.sendToIsolate(first);
    return first;
  }

  /// Wait for a changeset to be received by the server.
  Future<dynamic> processNextChange() async {
    do {
      dynamic next = await processNextCommand();
      if (next is CoopServerProcessData) {
        var data = next.data;
        var reader = BinaryReader(
            ByteData.view(data.buffer, data.offsetInBytes, data.length));
        int command = reader.readVarUint();
        if (command >= CoopCommand.minChangeId) {
          // it's a changeset
          return next;
        }
      }
    } while (true);
  }

  @override
  void sendToIsolate(dynamic data) {
    if (_manualDrive) {
      var next = _nextDataReceived;
      _nextDataReceived = null;
      if (next != null) {
        print("drive to completer $data");
        // We're already waiting for data, so just send this along.
        next?.complete(data);
        super.sendToIsolate(data);
      } else {
        // Queue it for when we next request it.
        print("drive to queued completer $data");
        _isolateQueue.add(data);
      }
    } else {
      super.sendToIsolate(data);
    }
  }
}

class TestCoopServer extends CoopServer {
  @override
  CoopIsolateHandler get handler => makeProcess;

  static Future<void> makeProcess(CoopIsolateArgument argument) async {
    var process = _TestCoopIsolateProcess();
    await process.initProcess(
        argument.sendPort, argument.options, argument.ownerId, argument.fileId);
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

  @override
  CoopIsolate makeIsolateInterface(int ownerId, int fileId) =>
      TestCoopIsolate(this, ownerId, fileId);
}

/// Manually test that the test server can be started
Future main() async {
  final server = TestCoopServer();
  print('Listening on port 8124');
  await server.listen(port: 8124);
}
