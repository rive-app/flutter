import 'dart:async' show Timer;
import 'dart:convert' show json;
import 'dart:io' show HttpServer, HttpRequest, WebSocket, WebSocketTransformer;

import 'dart:typed_data';

class CoopServer {
  void listen([int port = 8000]) {
    HttpServer.bind('localhost', port).then((HttpServer server) {
      print('[+]WebSocket listening at -- ws://localhost:$port/');
      server.listen((HttpRequest request) {
        WebSocketTransformer.upgrade(request).then((WebSocket ws) {
          ws.add("hello");
          var buffer = Uint8List(4);
          buffer[0] = 0;
          buffer[1] = 22;
          buffer[2] = 2;
          buffer[3] = 33;
          ws.add(buffer);
          ws.listen(
            (dynamic data) {
              print(
                  '\t\t${request?.connectionInfo?.remoteAddress} -- $data ${data.runtimeType}');
              Timer(const Duration(seconds: 1), () {
                if (ws.readyState == WebSocket.open) {
                  // checking connection state helps to avoid unprecedented errors
                  ws.add(
                    json.encode(
                      {
                        'data': 'from server at ${DateTime.now().toString()}',
                      },
                    ),
                  );
                }
              });
            },
            onDone: () => print('[+]Done :)'),
            onError: (dynamic err) => print('[!]Error -- ${err.toString()}'),
            cancelOnError: true,
          );
        }, onError: (dynamic err) => print('[!]Error -- ${err.toString()}'));
      }, onError: (dynamic err) => print('[!]Error -- ${err.toString()}'));
    }, onError: (dynamic err) => print('[!]Error -- ${err.toString()}'));
  }
}
