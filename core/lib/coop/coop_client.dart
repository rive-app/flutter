import 'dart:async';
import 'dart:typed_data';

import 'package:binary_buffer/binary_writer.dart';
import 'package:core/coop/change.dart';
import 'package:core/coop/coop_server_client.dart';
import 'package:core/coop/player.dart';
import 'package:core/coop/protocol_version.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'connect_result.dart';
import 'coop_reader.dart';
import 'coop_writer.dart';
import 'local_settings.dart';

typedef ChangeSetCallback = void Function(ChangeSet changeSet);
typedef WipeCallback = void Function();
typedef GetOfflineChangesCallback = Future<List<ChangeSet>> Function();
typedef HelloCallback = void Function(int clientId);
typedef PlayersCallback = void Function(List<Player>);

enum ConnectionState { disconnected, connecting, handshaking, connected }

class CoopClient extends CoopReader {
  final String url;
  WebSocketChannel _channel;
  CoopWriter _writer;
  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;
  ConnectionState get connectionState => _connectionState;
  ConnectionState _connectionState = ConnectionState.disconnected;
  int _reconnectAttempt = 0;
  Timer _reconnectTimer;
  Timer _pingTimer;
  final LocalSettings localSettings;
  final String fileId;
  int _clientId;
  int get clientId => _clientId;
  bool _allowReconnect = true;

  ChangeSetCallback changesAccepted;
  ChangeSetCallback changesRejected;
  ChangeSetCallback makeChanges;
  WipeCallback wipe;
  GetOfflineChangesCallback getOfflineChanges;
  HelloCallback gotClientId;
  PlayersCallback updatePlayers;

  CoopClient(
    String host,
    String path, {
    this.fileId,
    this.localSettings,
    int clientId,
  }) : url = '$host/v$protocolVersion/$path/$clientId' {
    _writer = CoopWriter(write);
  }

  Completer<IdRange> _allocateIdCompleter;

  Future<IdRange> allocateIds(int count) {
    _allocateIdCompleter = Completer<IdRange>();
    _writer.writeRequestIds(count);
    return _allocateIdCompleter.future;
  }

  Future<void> _reconnect() async {
    _reconnectTimer?.cancel();
    if (_reconnectAttempt < 1) {
      _reconnectAttempt = 1;
    }
    _reconnectAttempt *= 2;
    print("WILL WAIT ${_reconnectAttempt * 8000}");
    _reconnectTimer =
        Timer(Duration(milliseconds: _reconnectAttempt * 8000), connect);
  }

  void _ping() {
    if (_connectionState != ConnectionState.connected) {
      return;
    }
    _writer.writeCursor(0, 0);
    _pingTimer?.cancel();
    _pingTimer = Timer(const Duration(seconds: 30), _ping);
  }

  Future<bool> disconnect() async {
    _allowReconnect = false;
    _pingTimer?.cancel();
    await _channel.sink.close();
    return true;
  }

  Future<bool> forceReconnect() async {
    _allowReconnect = true;
    _pingTimer?.cancel();
    await _channel?.sink?.close();
    return true;
  }

  // Future<int> handshake(int sessionId, String fileId, String token) async {
  //   _writer.writeHello(sessionId, fileId, token);

  //   return 0;
  // }

  Completer<ConnectResult> _connectionCompleter;
  Future<ConnectResult> connect() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _channel = WebSocketChannel.connect(Uri.parse(url));
    _connectionCompleter = Completer<ConnectResult>();

    _connectionState = ConnectionState.connecting;

    _channel.stream.listen((dynamic data) {
      print("socket message: $data ${data.runtimeType}");
      if (data is Uint8List) {
        read(data);
      }
    }, onError: (dynamic error) {
      print("CONNECTION ERROR");
      _connectionState = ConnectionState.disconnected;
      _pingTimer?.cancel();
    }, onDone: () {
      print("CONNECTION MURDERED");
      _connectionState = ConnectionState.disconnected;
      _pingTimer?.cancel();
      _channel = null;
      _connectionCompleter?.complete(ConnectResult.networkError);
      _connectionCompleter = null;
      if (_allowReconnect) {
        _reconnect();
      }
    });
    return _connectionCompleter.future;
  }

  void write(Uint8List buffer) {
    assert(_connectionState == ConnectionState.handshaking ||
        _connectionState == ConnectionState.connected);
    _channel?.sink?.add(buffer);
  }

  @override
  void recvChange(ChangeSet changeSet) {
    // Make sure we do not apply changes that conflict with unacknowledged ones.
    makeChanges?.call(changeSet);
  }

  @override
  Future<void> recvGoodbye() async {
    // Handle the server telling us to disconnect.
    _allowReconnect = false;
    _connectionState = ConnectionState.disconnected;
    _pingTimer?.cancel();
    await _channel?.sink?.close();
    _channel = null;
    print("GOT GOODBYE");
    _connectionCompleter?.complete(ConnectResult.notAuthorized);
    _connectionCompleter = null;
  }

  /// Accept changes, remove the unacknowledge change that matches this
  /// changeId.
  @override
  Future<void> recvAccept(int changeId) async {
    // Kind of odd to assert a network requirement (this is something the server
    // would mess up) but it helps track things down if they go wrong.
    assert(_unacknowledged != null,
        "Shouldn't receive an accept without sending changes.");

    var change = _unacknowledged.id == changeId ? _unacknowledged : null;
    if (change != null) {
      _unacknowledged = null;
      changesAccepted?.call(change);
    }
    _sendFreshChanges();
  }

  @override
  Future<void> recvReject(int changeId) async {
    // The server rejected one of our changes. We need to re-apply the old
    // state.
    var change = _unacknowledged.id == changeId ? _unacknowledged : null;
    if (change != null) {
      _unacknowledged = null;
      changesRejected?.call(change);
    }
    _sendFreshChanges();
  }

  @override
  Future<void> recvHello(int clientId) async {
    _clientId = clientId;
    gotClientId?.call(clientId);
    _connectionState = ConnectionState.handshaking;
    _reconnectAttempt = 0;
    _isAuthenticated = true;

    // Once all offline changes are sent...

    assert(_connectionState == ConnectionState.handshaking);

    var changes = await getOfflineChanges?.call();
    _writer.writeSync(changes);
  }

  @override
  Future<void> recvReady() async {
    _connectionCompleter?.complete(ConnectResult.connected);
    _connectionCompleter = null;
    _ping();
  }

  final List<ChangeSet> _fresh = [];
  ChangeSet _unacknowledged;
  void queueChanges(ChangeSet changes) {
    // For now we send and save changes locally directly. Eventually we should
    // flatten them until they've been sent to a server as an atomic set.

    _fresh.add(changes);
    _sendFreshChanges();
  }

  // Need to call this on connect too.
  void _sendFreshChanges() {
    if (_unacknowledged != null ||
        _fresh.isEmpty ||
        _channel == null ||
        _channel.sink == null) {
      return;
    }
    var writer = BinaryWriter();
    _fresh.first.serialize(writer);
    _channel.sink.add(writer.uint8Buffer);
    _unacknowledged = _fresh.removeAt(0);
    // _fresh.clear();
  }

  @override
  Future<void> recvSync(List<ChangeSet> _) {
    throw UnsupportedError(
        "Client should never receive sync (gets sent only to server)");
  }

  @override
  Future<void> recvWipe() async {
    wipe?.call();
  }

  @override
  Future<void> recvIds(int min, int max) async {
    if (_allocateIdCompleter == null) {
      return;
    }
    var completer = _allocateIdCompleter;
    _allocateIdCompleter = null;
    completer.complete(IdRange(min, max));
  }

  @override
  Future<void> recvRequestIds(int amount) {
    throw UnsupportedError("Client should never receive request for ids");
  }

  @override
  Future<void> recvPlayers(List<Player> players) async {
    updatePlayers?.call(players);
  }
}
