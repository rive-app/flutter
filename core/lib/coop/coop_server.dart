import 'dart:io'
    show
        HttpRequest,
        HttpServer,
        InternetAddress,
        WebSocketException,
        WebSocketTransformer,
        stderr;

import 'coop_isolate.dart';

String _isolateKey(int ownerId, int fileId) => '$ownerId-$fileId';

abstract class CoopServer {
  final Map<String, CoopIsolate> _isolates = <String, CoopIsolate>{};

  CoopIsolateHandler get handler;
  HttpServer _server;

  int get editingFileCount => _isolates.keys.length;
  int get clientCount =>
      _isolates.values.fold(0, (count, isolate) => count + isolate.clientCount);

  bool remove(CoopIsolate isolate) {
    return _isolates.remove(_isolateKey(isolate.ownerId, isolate.fileId)) !=
        null;
  }

  Future<bool> close() async {
    await _server.close(force: true);
    return true;
  }

  Future<bool> listen({int port = 8000, Map<String, String> options}) async {
    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    } on Exception catch (ex) {
      print('[!]Error -- ${ex.toString()}');
      return false;
    }
    print('Listening ${InternetAddress.loopbackIPv4}:$port');
    _server.listen((HttpRequest request) async {
      var segments = request.requestedUri.pathSegments;
      print("SEG $segments");
      if (segments.isEmpty) {
        request.response.statusCode = 200;
        request.response.write('Healthy!');
        await request.response.close();
        return;
      }
      if (segments.length == 2) {
        int ownerId, fileId;
        try {
          ownerId = int.parse(segments[0]);
          fileId = int.parse(segments[1]);
        } on FormatException catch (error) {
          print('Invalid file id $error for ${request.requestedUri}.');
        }

        if (!await validate(request, ownerId, fileId)) {
          // TODO: fail the login.
        }
        try {
          var ws = await WebSocketTransformer.upgrade(request);
          String key = _isolateKey(ownerId, fileId);
          var isolate = _isolates[key];
          if (isolate == null) {
            isolate = CoopIsolate(this, ownerId, fileId);
            // Immediately make it available...
            _isolates[key] = isolate;
            if (!await isolate.spawn(handler, options)) {
              stderr.write('Unable to spawn isolate for file $key.');
              await ws.close();
              return;
            }
          }
          if (!await isolate.addClient(ws)) {
            stderr.write('Unable to add client for file $key. '
                'This could be due to a previous shutdown attempt, check logs for'
                ' indication of shutdown prior to this.');
            await ws.close();
          }
        } on WebSocketException catch (error) {
          stderr.write(error.toString());
        }
      }
    }, onError: (dynamic err) => stderr.write('[!]Error -- ${err.toString()}'));
    return true;
  }

  // Validate this instance is an expected server for ownerId/fileId. We need to
  // store a column with the assigned node for this file. Probably a
  // server_index column in the Files table that maps to:

  // wss://coop{server_index}.rive.app/{ownerId}/{fileId}
  // wss://coop1.rive.app/34/10
  // wss://coop2.rive.app/34/11

  // There'll be a row locking stored procedure that'll grab a valid
  // server_index for a file when it is first opened. This only runs if the
  // server_index is currently null. server_index is reset to null when all
  // clients have disconnected and some timeout elapses.
  Future<bool> validate(HttpRequest request, int ownerId, int fileId);
}
