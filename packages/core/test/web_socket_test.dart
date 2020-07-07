import 'dart:io';

import 'package:test/test.dart';
import 'package:core/web_socket/web_socket.dart';

class DummyServer {
  var dataList = <dynamic>[];
  HttpServer _server;

  Future<bool> close() async {
    await _server.close(force: true);
    return true;
  }

  Future<bool> listen({int port}) async {
    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);

    _server.listen((HttpRequest request) async {
      // Attempt to upgrade the HTTP connection to a web socket
      var ws = await WebSocketTransformer.upgrade(request);
      ws.listen(
        (dynamic data) {
          dataList.add(data);

          if (data as String == 'killme') {
            ws.close();
          }
        },
        onDone: () {
          ws.close();
        },
        onError: (dynamic err) => ws.close(),
        cancelOnError: true,
      );
    });
  }
}

class DummyClient extends ReconnectingWebsocketClient {
  var dataList = <dynamic>[];
  var states = <ConnectionState>[];
  DummyClient({Duration pingInterval = const Duration(seconds: 2)})
      : super(pingInterval: pingInterval);

  @override
  Future<void> handleData(dynamic data) async {
    dataList.add(data);
  }

  @override
  Future<void> onConnect() async {
    write('connect');
  }

  @override
  void onStateChange(ConnectionState data) {
    states.add(data);
  }

  @override
  String pingMessage() {
    return 'ping';
  }

  @override
  Future<String> getUrl() async {
    return 'ws://127.0.0.1:7777';
  }
}

void main() {
  test('valid cookie headers are generated', () {
    final token = 'thisisatoken==';
    final header = createCookieHeader(token);
    expect(header.length, 1);
    expect(header.keys.first, 'Cookie');
    expect(header.values.first.startsWith('spectre='), true);
    expect(header.keys.first.contains(' '), false);
    expect(header.values.first.endsWith(token), true);
    expect(header.values.first.contains(' '), false);
  });

  group('Reconnecting Websocket client tests', () {
    DummyServer server;
    DummyClient client;
    setUp(() async {
      server = DummyServer();
      await server.listen(port: 7777);
    });
    tearDown(() async {
      await server.close();
      await client.disconnect();
    });
    test('basics can connect & disconnect', () async {
      client = DummyClient();
      await client.connect();
      await Future<dynamic>.delayed(const Duration(milliseconds: 100));
      expect(server.dataList.first, 'connect');
      expect(server.dataList[1], 'ping');
      expect(server.dataList.length, 2);

      expect(client.states.first, ConnectionState.connected);
      expect(client.states.length, 1);
      expect(client.isPinging, true);
      expect(client.isReconnecting, false);
      await client.disconnect();
      expect(client.states[1], ConnectionState.disconnected);
      expect(client.isPinging, false);
      expect(client.isReconnecting, false);
    });
    test('ping does ping stuff', () async {
      client = DummyClient(pingInterval: const Duration(milliseconds: 10));
      await client.connect();
      await Future<dynamic>.delayed(const Duration(milliseconds: 100));
      expect(server.dataList.first, 'connect');
      // I dunno pings lots of times.
      expect(server.dataList.length > 5, true);
    });

    test('will reconnect', () async {
      client = DummyClient();
      await client.connect();
      await Future<dynamic>.delayed(const Duration(milliseconds: 100));
      expect(client.isReconnecting, false);
      expect(server.dataList.length, 2);
      client.write("killme");
      await Future<dynamic>.delayed(const Duration(milliseconds: 100));
      // first reconnect is wicket fast

      expect(client.states.last, ConnectionState.connected);
      expect(server.dataList.length, 5);
      expect(server.dataList[2], 'killme');
      client.write("killme");
      await Future<dynamic>.delayed(const Duration(milliseconds: 100));
      expect(client.states.last, ConnectionState.disconnected);
      // first reconnect is wicked fast
      expect(client.isReconnecting, true);
      expect(server.dataList.length, 6);
      expect(server.dataList.last, 'killme');
    });
  });
}
