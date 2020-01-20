import 'dart:async';
import 'dart:typed_data';

import 'package:binary_buffer/binary_writer.dart';
import 'package:core/coop/change.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'connect_result.dart';
import 'coop_command.dart';
import 'coop_reader.dart';
import 'coop_writer.dart';
import 'local_settings.dart';

typedef ChangeSetCallback = void Function(ChangeSet changeSet);
typedef ChangeIdCallback = bool Function(int from, int to);
typedef MakeChangeCallback = void Function(ObjectChanges change);

class CoopClient extends CoopReader {
  final String url;
  WebSocketChannel _channel;
  CoopWriter _writer;
  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;
  bool _isConnected = false;
  int _reconnectAttempt = 0;
  Timer _reconnectTimer;
  final LocalSettings localSettings;
  final String fileId;
  bool _allowReconnect = true;
  int _lastChangeId;

  ChangeSetCallback changesAccepted;
  ChangeSetCallback changesRejected;
  ChangeIdCallback changeObjectId;
  MakeChangeCallback makeChange;

  CoopClient(this.url, {this.fileId, this.localSettings}) {
    _writer = CoopWriter(write);
  }

  Future<void> _reconnect() async {
    _reconnectTimer?.cancel();
    if (_reconnectAttempt < 1) {
      _reconnectAttempt = 1;
    }
    _reconnectAttempt *= 2;
    print("WILL WAIT ${_reconnectAttempt * 500}");
    _reconnectTimer =
        Timer(Duration(milliseconds: _reconnectAttempt * 500), connect);
  }

  Future<bool> disconnect() async {
    _allowReconnect = false;
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

    _isConnected = false;

    _channel.stream.listen((dynamic data) {
      print("socket message: $data ${data.runtimeType}");
      if (data is Uint8List) {
        read(data);
      }
    }, onError: (dynamic error) {
      _isConnected = false;
    }, onDone: () {
      _isConnected = false;
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
    assert(_isConnected);
    _channel?.sink?.add(buffer);
  }

  @override
  Future<void> recvChange(ChangeSet changeSet) async {
    // Receiving other property changes.
    // Make sure we do not apply changes that conflict with unacknowledged ones.

    // That means that we need to re-apply them if that changeset is rejected.

    for (final objectChanges in changeSet.objects) {
      //change.objectId
      makeChange?.call(objectChanges);
    }
  }

  @override
  Future<void> recvGoodbye() async {
    // Handle the server telling us to disconnect.
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
  Future<void> recvHand(
      int session, String fileId, String token, int lastSeenChangeId) async {
    assert(false, 'Client should never receive hand.');
  }

  @override
  Future<void> recvHello() async {
    if (!_isConnected) {
      var session = await localSettings.getIntSetting('session') ?? 0;
      var token = await localSettings.getStringSetting('token') ?? '';
      var lastServerChangeId =
          await localSettings.getIntSetting('lastServerChangeId') ?? 0;
      _lastChangeId = await localSettings.getIntSetting('lastChangeId') ??
          CoopCommand.minChangeId;

      _reconnectAttempt = 0;
      _isConnected = true;

      _writer.writeHand(session, fileId, token, lastServerChangeId);
    }
  }

  @override
  Future<void> recvShake(int session, int lastSeenChangeId) async {
    if (session == 0) {
      _isAuthenticated = false;
      _connectionCompleter?.complete(ConnectResult.notAuthorized);
      _connectionCompleter = null;
    }
    _isAuthenticated = true;
    await localSettings.setIntSetting('session', session);
    _connectionCompleter?.complete(ConnectResult.connected);
    _connectionCompleter = null;
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

  ChangeSet makeChangeSet() {
    var changes = ChangeSet()
      ..id = _lastChangeId++
      ..objects = [];
    localSettings.setIntSetting('lastChangeId', _lastChangeId);
    return changes;
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
}
