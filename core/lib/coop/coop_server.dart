import 'dart:io'
    show
        HttpRequest,
        HttpServer,
        InternetAddress,
        WebSocketException,
        WebSocketTransformer,
        stderr;

import 'package:core/coop/protocol_version.dart';

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
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    } on Exception catch (ex) {
      print('[!]Error -- ${ex.toString()}');
      return false;
    }
    print('Listening ${InternetAddress.anyIPv4}:$port');
    _server.listen((HttpRequest request) async {
      var segments = request.requestedUri.pathSegments;
      print("SEG $segments");
      if (segments.isEmpty) {
        request.response.statusCode = 200;
        request.response.write('Healthy!');
        await request.response.close();
        return;
      }
      if (segments.length == 4) {
        int version, ownerId, fileId;
        String token;
        try {
          // kill the v in v2
          version = int.parse(segments[0].substring(1));
          ownerId = int.parse(segments[1]);
          fileId = int.parse(segments[2]);
          token = segments[3];
        } on FormatException catch (error) {
          print('Invalid file id $error for ${request.requestedUri}.');
          request.response.statusCode = 422;
          await request.response.close();
          return;
        }
        if (version != protocolVersion) {
          request.response.statusCode = 418;
          await request.response.close();
          return;
        }

        // TODO: Max fix user owner ids :)
        int userOwnerId = await validate(request, ownerId, fileId, token);
        if(userOwnerId == null) {
          request.response.statusCode = 403;
          await request.response.close();
          return;
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
          if (!await isolate.addClient(userOwnerId, ws)) {
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
  
  // Also take this opportunity to check that the token matches a valid user.
  Future<int> validate(
      HttpRequest request, int ownerId, int fileId, String token);
}
