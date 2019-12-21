import 'dart:async';
import 'dart:typed_data';

import 'package:core/coop/change.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'connect_result.dart';
import 'coop_reader.dart';
import 'coop_writer.dart';
import 'local_settings.dart';

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

  // Future<int> handshake(int sessionId, String fileId, String token) async {
  //   _writer.writeHello(sessionId, fileId, token);

  //   return 0;
  // }

  Completer<ConnectResult> _connectionCompleter;
  Future<ConnectResult> connect() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    print("CALLING CONNECT $url");
    _channel = WebSocketChannel.connect(Uri.parse(url));
    _connectionCompleter = Completer<ConnectResult>();

    _isConnected = false;
    // first message to force a message back...
    print("GO!");

    _channel.stream.listen((dynamic data) {
      print("socket message: $data ${data.runtimeType}");
      if (data is Uint8List) {
        read(data);
      }
      // _channel.stream.listen(_dataHandler);
    }, onError: (dynamic error) {
      _isConnected = false;
      print("ERROR $error");
      //_reconnect();
    }, onDone: () {
      _isConnected = false;
      _channel = null;
      print("DONE!");
      _connectionCompleter?.complete(ConnectResult.networkError);
      _connectionCompleter = null;
      _reconnect();
    });
    return _connectionCompleter.future;
  }

  void write(Uint8List buffer) {
    assert(_isConnected);
    _channel?.sink?.add(buffer);
  }

  @override
  Future<void> recvChange(ChangeSet changes) {
    // TODO: implement recvChange
  }

  @override
  Future<void> recvGoodbye() {
    // TODO: implement recvGoodbye
  }

  @override
  Future<void> recvHand(
      int session, String fileId, String token, int lastSeenChangeId) {
    assert(false, 'Client should never receive hand.');
  }

  @override
  Future<void> recvHello() async {
    print("GOT HELLO? $_isConnected");
    if (!_isConnected) {
      var session = await localSettings.getIntSetting('session') ?? 0;
      var token = await localSettings.getStringSetting('token') ?? '';
      var lastServerChangeId =
          await localSettings.getIntSetting('lastServerChangeId') ?? 0;

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
}
