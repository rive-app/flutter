import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:core/debounce.dart';

import 'change.dart';
import 'coop_server.dart';
import 'coop_server_client.dart';

typedef CoopIsolateHandler = void Function(CoopIsolateArgument);
typedef CoopIsolateHandlerMaker = CoopIsolateHandler Function();

class CoopIsolate {
  static const Duration killTimeout = Duration(seconds: 3);
  final ReceivePort _receiveFromIsolatePort = ReceivePort();
  Timer _killTimer;
  SendPort _sendToIsolatePort;
  Isolate _isolate;
  final Map<int, WebSocket> _clients = {};

  /// Sockets queue during concurrent open request.
  final List<_WebSocketDelayedAdd> _queuedSockets = [];

  Completer<bool> _shutdownCompleter;
  final CoopServer server;
  final int ownerId;
  final int fileId;
  CoopIsolate(this.server, this.ownerId, this.fileId);
  int get clientCount => _clients.length;

  Future<bool> addClient(
      int userOwnerId, int desiredClientId, WebSocket socket) async {
    if (_sendToIsolatePort == null) {
      // tryign to add while booting.
      var queued = _WebSocketDelayedAdd(userOwnerId, desiredClientId, socket);
      _queuedSockets.add(queued);
      return queued.completer.future;
    }
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

    // Make sure the chosen id is available.
    var ids = List<int>.from(_clients.keys)..sort();
    var id = ids.isEmpty ? 0 : ids.reduce(max) + 1;
    _clients[id] = socket;

    _sendToIsolatePort
        .send(_CoopServerAddClient(id, userOwnerId, desiredClientId));
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

  Future<bool> shutdown() async {
    // Don't attempt a shutdown if one is already in progress.
    if (_shutdownCompleter != null) {
      return false;
    }
    _shutdownCompleter = Completer<bool>();
    _sendToIsolatePort.send(_CoopServerShutdown());
    return _shutdownCompleter.future;
  }

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
        // Make sure any queued add operations are completed when the isolate
        // has spawned.
        for (final q in _queuedSockets) {
          addClient(q.userOwnerId, q.clientId, q.socket)
              .then(q.completer.complete);
        }
        _queuedSockets.clear();
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
}

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

abstract class CoopIsolateProcess {
  final ReceivePort _receiveFromMainPort = ReceivePort();
  SendPort _sendToMainPort;
  final Map<int, CoopServerClient> _clients = {};
  final Set<CoopServerClient> _dirtyCursors = {};

  CoopIsolateProcess() {
    _receiveFromMainPort.listen(_receive);
  }

  Iterable<CoopServerClient> get clients => _clients.values;

  bool attemptChange(CoopServerClient client, ChangeSet changes);
  ChangeSet buildFileChangeSet();

  // bool remove(CoopServerClient client) => _clients.remove(client);

  Future<bool> initialize(int ownerId, int fileId, Map<String, String> options);

  void cursorChanged(CoopServerClient client) {
    _dirtyCursors.add(client);
    debounce(_propagateCursors, duration: const Duration(milliseconds: 50));
  }

  void _propagateCursors() {
    var cursors = _dirtyCursors.toList(growable: false);
    _dirtyCursors.clear();
    var players = _clients.values;
    for (final client in players) {
      // remove own cursor
      var sendCursors = cursors
          .where((cursorClient) => cursorClient != client)
          .toList(growable: false);
      if (sendCursors.isNotEmpty) {
        client.writer.writeCursors(cursors);
      }
    }
  }

  Future<bool> initProcess(SendPort sendToMainPort, Map<String, String> options,
      int ownerId, int fileId) async {
    _sendToMainPort = sendToMainPort;
    if (await initialize(ownerId, fileId, options)) {
      _sendToMainPort.send(_receiveFromMainPort.sendPort);
      return true;
    }
    return false;
  }

  /// Save the data somewhere persistent where we can re-load it later.
  Future<void> persist();

  void propagateChanges(CoopServerClient client, ChangeSet changes);

  /// Send the list of players to all players.
  void propagatePlayers() {
    var players = _clients.values.where((client) => client.isReady);
    for (final client in players) {
      if (!client.isReady) {
        continue;
      }
      client.writer.writePlayers(players);
    }
  }

  int nextClientId();

  Future<bool> shutdown();
  void write(CoopServerClient client, Uint8List data) {
    _sendToMainPort.send(_CoopServerProcessData(client.id, data));
  }

  Future<void> _receive(dynamic data) async {
    if (data is _CoopServerAddClient) {
      int actualClientId = data.clientId;
      // Check if the client id the connection wants to use is valid.
      if (actualClientId == null || actualClientId < 1) {
        actualClientId = nextClientId();
        debounce(persist, duration: const Duration(seconds: 1));
      } else {
        // Check if that id is already in use by another connected client.
        for (final client in _clients.values) {
          if (client.clientId == actualClientId) {
            actualClientId = nextClientId();
            debounce(persist, duration: const Duration(seconds: 1));
            break;
          }
        }
      }
      _clients[data.id] =
          CoopServerClient(this, data.id, data.userOwnerId, actualClientId);
    } else if (data is _CoopServerRemoveClient) {
      var client = _clients[data.id];
      if (client != null) {
        _clients.remove(client.id);
        propagatePlayers();
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

  void onClientReady(CoopServerClient client) {
    propagatePlayers();
  }
}

class _CoopServerAddClient {
  final int id;
  final int userOwnerId;
  final int clientId;
  _CoopServerAddClient(this.id, this.userOwnerId, this.clientId);
}

class _CoopServerProcessData {
  final int id;
  final Uint8List data;
  _CoopServerProcessData(this.id, this.data);
}

class _CoopServerRemoveClient {
  final int id;
  _CoopServerRemoveClient(this.id);
}

class _CoopServerShutdown {}

class _WebSocketDelayedAdd {
  final Completer<bool> completer = Completer<bool>();
  final WebSocket socket;
  final int userOwnerId;
  final int clientId;

  _WebSocketDelayedAdd(this.userOwnerId, this.clientId, this.socket);
}
