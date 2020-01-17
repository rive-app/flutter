// import 'dart:async';
import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'dart:typed_data';

import 'coop_server.dart';
import 'coop_server_client.dart';
import 'coop_session.dart';
import 'change.dart';
import 'package:core/core.dart';

typedef CoopIsolateHandler = void Function(CoopIsolateArgument);
typedef CoopIsolateHandlerMaker = CoopIsolateHandler Function();

class CoopIsolateArgument {
  int ownerId;
  int fileId;
  final SendPort sendPort;
  final Map<String, String> options;
  CoopIsolateArgument(
    this.ownerId,
    this.fileId, {
    this.sendPort,
    this.options,
  });
}

class _CoopServerProcessData {
  final int id;
  final Uint8List data;
  _CoopServerProcessData(this.id, this.data);
}

class _CoopServerAddClient {
  final int id;
  _CoopServerAddClient(this.id);
}

class _CoopServerRemoveClient {
  final int id;
  _CoopServerRemoveClient(this.id);
}

class _CoopServerShutdown {}

class CoopIsolate {
  static const Duration killTimeout = Duration(seconds: 3);
  final ReceivePort _receiveFromIsolatePort = ReceivePort();
  Timer _killTimer;
  SendPort _sendToIsolatePort;
  Isolate _isolate;
  final Map<int, WebSocket> _clients = {};
  int get clientCount => _clients.length;
  Completer<bool> _shutdownCompleter;
  final CoopServer server;
  final int ownerId;
  final int fileId;
  CoopIsolate(this.server, this.ownerId, this.fileId);

  Future<bool> spawn(void entryPoint(CoopIsolateArgument message),
      Map<String, String> options) async {
    var completer = Completer<bool>();
    _isolate = await Isolate.spawn(
        entryPoint,
        CoopIsolateArgument(ownerId, fileId,
            sendPort: _receiveFromIsolatePort.sendPort, options: options));
    _receiveFromIsolatePort.listen((dynamic data) {
      if (data is SendPort && _sendToIsolatePort == null) {
        _sendToIsolatePort = data;
        completer.complete(true);
      } else if (data is _CoopServerProcessData) {
        _clients[data.id]?.add(data.data);
      } else if (data is _CoopServerShutdown && _shutdownCompleter != null) {
        _isolate?.kill();
        _isolate = null;
        _shutdownCompleter.complete(true);
        server.remove(this);
      }
    });
    return completer.future;
  }

  Future<bool> shutdown() async {
    // Don't attempt a shutdown if one is already in progress.
    if (_shutdownCompleter != null) {
      return false;
    }
    _shutdownCompleter = Completer<bool>();
    _sendToIsolatePort.send(_CoopServerShutdown());
    return _shutdownCompleter.future;
  }

  Future<bool> addClient(WebSocket socket) async {
    // Cancel a kill timer if we have one. This prevents the shutdown from
    // occuring if a client reconnects during the graceperiod between 0
    // connections and shutdown.
    _killTimer?.cancel();

    if (_shutdownCompleter != null) {
      // We do this to make sure there's no parallel creation of coop isolates.
      // While the shutdown is occurring, clients could still attempt to
      // connect, we'll fail the connection, our client will retry a little
      // later.
      print("Not allowed to add a client while completing shutdown.");
      return false;
    }
    int id = _clients.keys.length;
    _clients[id] = socket;

    _sendToIsolatePort.send(_CoopServerAddClient(id));
    socket.listen(
      (dynamic data) {
        if (data is Uint8List) {
          // If we get binary data, send it along to the isolate.
          _sendToIsolatePort.send(_CoopServerProcessData(id, data));
        }
      },
      onDone: () {
        // Client disconnected.
        _clients.remove(id);
        _sendToIsolatePort.send(_CoopServerRemoveClient(id));
        if (_clients.isEmpty) {
          _killTimer?.cancel();
          _killTimer = Timer(killTimeout, shutdown);
        }
      },
      onError: (dynamic err) => print('[!]Error -- ${err.toString()}'),
      cancelOnError: true,
    );

    return true;
  }

  // static Future<void> _process(CoopIsolateArgument arguments) async {
  //   var isolateProcess = arguments.process;
  //   if (!await isolateProcess.initProcess(
  //       arguments.sendPort, arguments.options)) {
  //     print('Failed to initialize coop isolate process.');
  //   }
  //   // arguments.sendPort.send(receiveFromMainPort.sendPort);
  //   // arguments.sendPort.send(Uint8List.fromList([1, 2, 3, 4]));
  //   // print("TRY LISTEN2");
  //   // receiveFromMainPort.listen((dynamic data) {
  //   //   print("ISOLATE GOT $data");
  //   // });
  // }
}

abstract class CoopIsolateProcess {
  final ReceivePort _receiveFromMainPort = ReceivePort();
  SendPort _sendToMainPort;
  final Map<int, CoopServerClient> _clients = {};
  CoopIsolateProcess() {
    _receiveFromMainPort.listen(_receive);
  }

  Future<void> _receive(dynamic data) async {
    print("RECEIVING DATA $data");
    if (data is _CoopServerAddClient) {
      _clients[data.id] = CoopServerClient(this, data.id);
    } else if (data is _CoopServerRemoveClient) {
      var client = _clients[data.id];
      if (client != null) {
        _clients.remove(client);
      }
    } else if (data is _CoopServerProcessData) {
      _clients[data.id]?.receiveData(data.data);
      // _clients.add(CoopServerClient(this, _clients.length));
    } else if (data is _CoopServerShutdown) {
      await shutdown();
      // Let main thread know the shutdown completed.
      _sendToMainPort.send(data);
    }
  }

  // bool remove(CoopServerClient client) => _clients.remove(client);

  Future<bool> initProcess(SendPort sendToMainPort, Map<String, String> options,
      int ownerId, int fileId) async {
    _sendToMainPort = sendToMainPort;
    if (await initialize(ownerId, fileId, options)) {
      _sendToMainPort.send(_receiveFromMainPort.sendPort);
      return true;
    }
    return false;
  }

  void write(CoopServerClient client, Uint8List data) {
    _sendToMainPort.send(_CoopServerProcessData(client.id, data));
  }

  bool attemptChange(ChangeSet changes);

  Future<bool> initialize(int ownerId, int fileId, Map<String, String> options);
  Future<bool> saveData(String key, Uint8List data);
  Future<Uint8List> loadData(String key);
  Future<bool> shutdown();
  Future<CoopSession> login(String token, int session);
}
