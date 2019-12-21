import 'dart:async' show Timer;
import 'dart:convert' show json;
import 'dart:io' show HttpServer, HttpRequest, WebSocket, WebSocketTransformer;

import 'dart:typed_data';

import 'package:core/coop/change.dart';

import 'coop_reader.dart';
import 'coop_writer.dart';

class CoopServerClient extends CoopReader {
  CoopWriter _writer;
  final WebSocket socket;
  final CoopServer server;
  final HttpRequest request;

  CoopServerClient(this.server, this.socket, this.request) {
    _writer = CoopWriter(write);

    _writer.writeHello();

    // ws.add("hello");
    // var buffer = Uint8List(4);
    // buffer[0] = 0;
    // buffer[1] = 22;
    // buffer[2] = 2;
    // buffer[3] = 33;
    // socket.add(buffer);
    socket.listen(
      (dynamic data) {
        if (data is Uint8List) {
          read(data);
        }
        // print(
        //     '\t\t${request?.connectionInfo?.remoteAddress} -- $data ${data.runtimeType}');
        // Timer(const Duration(seconds: 1), () {
        //   if (socket.readyState == WebSocket.open) {
        //     // checking connection state helps to avoid unprecedented errors
        //     socket.add(
        //       json.encode(
        //         {
        //           'data': 'from server at ${DateTime.now().toString()}',
        //         },
        //       ),
        //     );
        //   }
        // });
      },
      onDone: () => server.remove(this),
      onError: (dynamic err) => print('[!]Error -- ${err.toString()}'),
      cancelOnError: true,
    );
  }

  void write(Uint8List buffer) {
    // assert(_isConnected);
    socket.add(buffer);
  }

  @override
  Future<void> recvChange(ChangeSet changes) {
    // TODO: implement recvChange
    throw UnimplementedError();
  }

  @override
  Future<void> recvGoodbye() {
    // TODO: implement recvGoodbye
    throw UnimplementedError();
  }

  @override
  Future<void> recvHand(
      int session, String fileId, String token, int lastServerChangeId) {
    // TODO: implement recvHand
    print("GOT THE HAND $session $fileId $token $lastServerChangeId");
    // somehow validate this.
    _writer.writeShake(session, 2);
  }

  @override
  Future<void> recvHello() {
    // TODO: implement recvHello
    throw UnimplementedError();
  }

  @override
  Future<void> recvShake(int session, int lastSeenChangeId) {
    // TODO: implement recvShake
    throw UnimplementedError();
  }
}

class CoopServer {
  final List<CoopServerClient> clients = <CoopServerClient>[];

  void remove(CoopServerClient client) {
    clients.remove(client);
  }

  Future<bool> listen([int port = 8000]) async {
    HttpServer server;
    try {
      server = await HttpServer.bind('localhost', port);
    } on Exception catch (ex) {
      print('[!]Error -- ${ex.toString()}');
      return false;
    }
    print('Listening localhost:$port');
    server.listen((HttpRequest request) {
      print("GOT A CONNEC!");
      WebSocketTransformer.upgrade(request).then((WebSocket ws) {
        clients.add(CoopServerClient(this, ws, request));
      }, onError: (dynamic err) => print('[!]Error -- ${err.toString()}'));
    }, onError: (dynamic err) => print('[!]Error -- ${err.toString()}'));
    return true;
  }
}
