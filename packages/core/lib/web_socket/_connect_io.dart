import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Creates a new WebSocket connection.
///
/// Connects to [uri] using and returns a channel that can be used to
/// communicate over the resulting socket
///
/// Takes an optional map of headers. Designed to manually pass
/// up cookies
WebSocketChannel connect(Uri uri, [Map<String, String> headers]) =>
    IOWebSocketChannel.connect(uri, headers: headers);
