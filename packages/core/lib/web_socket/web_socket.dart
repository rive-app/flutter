import 'dart:async';

import 'package:core/error_logger/error_logger.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '_connect_io.dart'
    if (dart.library.io) '_connect_io.dart'
    if (dart.library.html) '_connect_html.dart' as platform;

/// Custom ws channel implementation to expose the headers for
/// io-based web socket initiated connections. WebSocketChannel
/// only exposes the uri.
///
/// Needed to set the cookie header for non-browser clients.
class RiveWebSocketChannel extends WebSocketChannel {
  RiveWebSocketChannel(StreamChannel<List<int>> channel) : super(channel);

  /// Creates a web socket channel with the given authenication token.
  /// For non browser based connections, this will be manually placed
  /// into the headers as a cookie
  static WebSocketChannel connect(Uri uri, [String token]) {
    final cookieHeader = token != null ? createCookieHeader(token) : null;
    return platform.connect(uri, cookieHeader);
  }
}

/// Creates a valid cooke header
Map<String, String> createCookieHeader(String token) =>
    {'Cookie': 'spectre=$token'};

enum ConnectionState { disconnected, connected }

abstract class ReconnectingWebsocketClient {
  final Duration pingInterval;
  WebSocketChannel _channel;

  ConnectionState get connectionState => _connectionState;
  ConnectionState _connectionState = ConnectionState.disconnected;

  void _changeState(ConnectionState state) {
    if (_connectionState != state) {
      _connectionState = state;
      onStateChange(_connectionState);
    }
  }

  int _reconnectAttempt = 0;
  Timer _reconnectTimer;
  Timer _pingTimer;

  bool _allowReconnect = true;

  bool get isReconnecting => _reconnectTimer?.isActive ?? false;
  bool get isPinging => _pingTimer?.isActive ?? false;

  ReconnectingWebsocketClient(
      {this.pingInterval = const Duration(seconds: 120)});

  void _ping() {
    if (!isConnected) {
      return;
    }
    write(pingMessage());
    _pingTimer?.cancel();
    _pingTimer = Timer(pingInterval, _ping);
  }

  void _reconnect() {
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _reconnectTimer =
        Timer(Duration(milliseconds: _reconnectAttempt * 8000), connect);
    if (_reconnectAttempt < 1) {
      _reconnectAttempt = 1;
    }
    _reconnectAttempt *= 2;
  }

  void dispose() {
    disconnect();
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _reconnectTimer = null;
  }

  bool get isConnected => _connectionState == ConnectionState.connected;

  Future<bool> disconnect() async {
    _allowReconnect = false;
    if (_channel != null) {
      await _channel.sink.close();
    }
    await _subscription?.cancel();
    _pingTimer?.cancel();
    await _disconnected();
    return true;
  }

  StreamSubscription _subscription;

  Future<void> _onStreamData(dynamic data) async {
    // we got data, we're connected might as well reset the reconnect attempt.

    _reconnectAttempt = 0;
    // We pause and resume the stream once our read has fully completed. This
    // allows us to avoid race conditions with processing events that are
    // expected to happen in order.
    _subscription.pause();

    await handleData(data);

    _subscription.resume();
  }

  Future<void> onConnect();
  Future<void> handleData(dynamic data);
  Future<String> getUrl();

  void onStateChange(ConnectionState state);
  String pingMessage();

  Future<void> connect() async {
    try {
      String url = await getUrl();
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
      _channel = RiveWebSocketChannel.connect(Uri.parse(url));
      _changeState(ConnectionState.connected);
      await onConnect();
      _ping();
      runZoned(() {
        _subscription =
            _channel.stream.listen(_onStreamData, onError: (dynamic error) {
          _disconnected();
        }, onDone: () async {
          await _disconnected();
          if (_allowReconnect) {
            _reconnect();
          }
        });
      }, onError: (Object error, StackTrace stackTrace) {
        try {
          ErrorLogger.instance.reportException(error, stackTrace);
        } on Exception catch (e) {
          print('Failed to report: $e');
          print('Error was: $error, $stackTrace');
        }
      });
    } on Exception catch (e) {
      print('Failed to establish a websocket connection: $e');
      await _disconnected();
      if (_allowReconnect) {
        _reconnect();
      }
    }
  }

  Future<void> _disconnected() async {
    _changeState(ConnectionState.disconnected);
    if (_channel != null && _channel.sink != null) {
      await _channel.sink.close();
    }
    _channel = null;
  }

  void write(dynamic data) {
    assert(_connectionState == ConnectionState.connected);
    _channel?.sink?.add(data);
  }
}
