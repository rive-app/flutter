import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:core/debounce.dart';
import 'package:meta/meta.dart';
import 'package:utilities/logger.dart';

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
  int nextClientId = 0;

  /// Sockets queue during concurrent open request.
  final List<_WebSocketDelayedAdd> _queuedSockets = [];

  Completer<bool> _shutdownCompleter;
  final CoopServer server;
  final int fileId;
  CoopIsolate(this.server, this.fileId);
  int get clientCount => _clients.length;
  String get privateApiHost => null;

  /// Allow implementations to override sending to isolate. This allows tests to
  /// do things like delay sending operations to the isolate in order to test
  /// sequence of send/receive events that deterministically allow edge cases to
  /// occur.
  @protected
  void sendToIsolate(dynamic data) => _sendToIsolatePort.send(data);

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
    var id = nextClientId++;
    _clients[id] = socket;

    sendToIsolate(CoopServerAddClient(id, userOwnerId, desiredClientId));
    socket.listen(
      (dynamic data) {
        if (data is Uint8List) {
          // If we get binary data, send it along to the isolate.
          sendToIsolate(CoopServerProcessData(id, data));
        }
      },
      onDone: () {
        // Client disconnected.
        _clients.remove(id);
        sendToIsolate(CoopServerRemoveClient(id));
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
    var completer = Completer<bool>();
    _shutdownCompleter = completer;
    sendToIsolate(_CoopServerShutdown());
    return completer.future;
  }

  Future<bool> spawn(void entryPoint(CoopIsolateArgument message),
      Map<String, String> options) async {
    var completer = Completer<bool>();

    // Make sure to listen before spawn.
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
      } else if (data is CoopServerProcessData) {
        _clients[data.id]?.add(data.data);
      } else if (data is _CoopServerShutdown) {
        _isolate?.kill();
        _isolate = null;
        print('Killed isolate for $fileId');

        /// This was a requested shutdown
        if (_shutdownCompleter != null) {
          _shutdownCompleter.complete(true);
          server.remove(this);
        } else {
          // we died on boot.
          completer.complete(false);
        }
      }
    });

    // Spawn it.
    _isolate = await Isolate.spawn(
        entryPoint,
        CoopIsolateArgument(fileId,
            privateApiHost: privateApiHost,
            sendPort: _receiveFromIsolatePort.sendPort,
            options: options));
    return completer.future;
  }
}

class CoopIsolateArgument {
  int fileId;
  final String privateApiHost;
  final SendPort sendPort;
  final Map<String, String> options;
  CoopIsolateArgument(
    this.fileId, {
    this.privateApiHost,
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

  Future<bool> initialize(int fileId, Map<String, String> options);

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

  Future<bool> initProcess(
      SendPort sendToMainPort, Map<String, String> options, int fileId) async {
    print('initializing process for $fileId');
    configureLogger();
    _sendToMainPort = sendToMainPort;
    if (await initialize(fileId, options)) {
      print('initialized ok, sending sendPort to main thread for $fileId');
      _sendToMainPort.send(_receiveFromMainPort.sendPort);
      return true;
    } else {
      print('init failed, send shutdown for $fileId');
      _sendToMainPort.send(_CoopServerShutdown());
    }
    return false;
  }

  /// Save the data somewhere persistent where we can re-load it later.
  Future<void> persist();

  void propagateChanges(CoopServerClient client, ChangeSet changes);

  /// Send the list of players to all players.
  void propagatePlayers() {
    print('propagating players');
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
    _sendToMainPort.send(CoopServerProcessData(client.id, data));
  }

  Future<void> _receive(dynamic data) async {
    if (data is CoopServerAddClient) {
      int actualClientId = data.clientId;
      print('adding a client $actualClientId');
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
    } else if (data is CoopServerRemoveClient) {
      print('removing a client ${data.id}');
      var client = _clients[data.id];
      if (client != null) {
        _clients.remove(client.id);
        propagatePlayers();
      }
    } else if (data is CoopServerProcessData) {
      _clients[data.id]?.receiveData(data.data);
      // _clients.add(CoopServerClient(this, _clients.length));
    } else if (data is _CoopServerShutdown) {
      print('received shutdown from main thread');
      await shutdown();
      // Let main thread know the shutdown completed.
      _sendToMainPort.send(data);
    }
  }

  void onClientReady(CoopServerClient client) {
    print('client is ready, propagate players');
    propagatePlayers();
  }

  /// A client is requesting to restore a revision id.
  Future<void> restoreRevision(int revisionId);
}

class CoopServerAddClient {
  final int id;
  final int userOwnerId;
  final int clientId;
  CoopServerAddClient(this.id, this.userOwnerId, this.clientId);
}

class CoopServerProcessData {
  final int id;
  final Uint8List data;
  CoopServerProcessData(this.id, this.data);
}

class CoopServerRemoveClient {
  final int id;
  CoopServerRemoveClient(this.id);
}

class _CoopServerShutdown {}

class _WebSocketDelayedAdd {
  final Completer<bool> completer = Completer<bool>();
  final WebSocket socket;
  final int userOwnerId;
  final int clientId;

  _WebSocketDelayedAdd(this.userOwnerId, this.clientId, this.socket);
}
