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
    final cookieHeader = token != null ? {'Cookie': token} : null;
    return platform.connect(uri, cookieHeader);
  }
}
