import 'dart:async';
import 'dart:typed_data';

import 'package:binary_buffer/binary_writer.dart';
import 'package:core/coop/change.dart';
import 'package:core/coop/protocol_version.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'connect_result.dart';
import 'coop_reader.dart';
import 'coop_writer.dart';
import 'local_settings.dart';

typedef ChangeSetCallback = void Function(ChangeSet changeSet);
typedef ChangeIdCallback = bool Function(int from, int to);
typedef WipeCallback = void Function();
typedef GetOfflineChangesCallback = Future<List<ChangeSet>> Function();

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
  bool _allowReconnect = true;

  ChangeSetCallback changesAccepted;
  ChangeSetCallback changesRejected;
  ChangeIdCallback changeObjectId;
  ChangeSetCallback makeChanges;
  WipeCallback wipe;
  GetOfflineChangesCallback getOfflineChanges;

  CoopClient(String host, String path, {this.fileId, this.localSettings})
      : url = '$host/v$protocolVersion/$path' {
    _writer = CoopWriter(write);
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
    await _channel.sink.close();
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
  Future<void> recvAccept(int changeId, int serverChangeId) async {
    // Kind of odd to assert a network requirement (this is something the server
    // would mess up) but it helps track things down if they go wrong.
    assert(_unacknowledged != null,
        "Shouldn't receive an accept without sending changes.");

    var change = _unacknowledged.id == changeId ? _unacknowledged : null;
    if (change != null) {
      _unacknowledged = null;
      changesAccepted?.call(change);
    }
    await localSettings.setIntSetting('lastServerChangeId', serverChangeId);
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
  Future<void> recvHand(String token) async {
    assert(false, 'Client should never receive hand.');
  }

  @override
  Future<void> recvHello() async {
    _connectionState = ConnectionState.handshaking;
    _reconnectAttempt = 0;
    _isAuthenticated = true;

    // TODO: send offline changes (N.B. this will actually be hello when we fix
    // the connection process)

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

  @override
  Future<void> recvChangeId(int from, int to) async {
    if (changeObjectId?.call(from, to) ?? false) {
      for (final changeSet in _fresh) {
        for (final objectChanges in changeSet.objects) {
          if (objectChanges.objectId == from) {
            objectChanges.objectId = to;
          }
        }
      }
    }
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
        "Client should never receive sync (gets sent only to server");
  }

  @override
  Future<void> recvWipe() async {
    wipe?.call();
  }
}
