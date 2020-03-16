import 'package:web_socket_channel/html.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Creates a new WebSocket connection.
///
/// Connects to [uri] using and returns a channel that can be used to
/// communicate over the resulting socket.
///
/// Ignores any headers passed, as this is here to manually pass in
/// cookies, which is unnecessary for browser-based clients.
WebSocketChannel connect(Uri uri, [Map<String, String> headers]) =>
    HtmlWebSocketChannel.connect(uri);
