import 'dart:io'
    show
        HttpRequest,
        HttpServer,
        InternetAddress,
        WebSocketException,
        WebSocketTransformer;

import 'package:logging/logging.dart';

import 'package:core/coop/protocol_version.dart';
import 'package:core/coop/coop_isolate.dart';

final Logger log = Logger('CoopServer');

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
    } on Exception catch (e) {
      log.severe('Unable to bind port to http server: $e');
      return false;
    }
    log.info('Listening on ${InternetAddress.anyIPv4}:$port');
    _server.listen((HttpRequest request) async {
      var segments = request.requestedUri.pathSegments;
      log.finest('Received message ${_segmentsToString(segments)}');
      // If there's no URI segments, return health status
      if (segments.length != 5 && segments.length != 6) {
        request.response.statusCode = 200;
        request.response.write('Healthy!');
        await request.response.close();
        return;
      }

      // If there are 5 segments, this is a request to start a web socket
      // connection with full user validation. This is going to be deprecated
      // in favour of the 4 segment unvalidated call once the coop server
      // moves into the internal network
      // /v<version>/<ownerId>/<fileId>/<token>/<clientId>
      int version, ownerId, fileId, clientId, userOwnerId;
      String token;
      if (segments.length == 5) {
        try {
          if (segments[0].length < 2) {
            log.info('Invalid protocol version ${_segmentsToString(segments)}');
            request.response.statusCode = 422;
            await request.response.close();
            return;
          }
          // kill the v in v2
          version = int.parse(segments[0].substring(1));
          ownerId = int.parse(segments[1]);
          fileId = int.parse(segments[2]);
          token = segments[3];
          try {
            clientId = int.parse(segments[4]);
          } on FormatException catch (_) {
            log.info('Invalid clientid: ${segments[4]}');
            clientId = 0;
          }
        } on FormatException catch (e) {
          log.info('Invalid message ${_segmentsToString(segments)}'
              ' $e for ${request.requestedUri}.');
          request.response.statusCode = 422;
          await request.response.close();
          return;
        }
        if (version != protocolVersion) {
          request.response.statusCode = 418;
          await request.response.close();
          return;
        }

        userOwnerId = await validate(request, ownerId, fileId, token);
        if (userOwnerId == null) {
          log.info('Authentication failure for message'
              ' ${_segmentsToString(segments)}');
          request.response.statusCode = 403;
          await request.response.close();
          return;
        }
      }

      // Web socket request from the 2D service
      // This replaces the code for parsing segments of length 5
      // when the co-op server moves inside the VPC
      // The format expected is:
      // 'v<version>/<ownerId>/<fileId>/<userOwnerId>/<clientId>
      else if (segments.length == 6) {
        try {
          log.finest('Proxy web socket request');
          final data = WebSocketData.fromSegments(segments);
          // Remove this unnecessary business when validating
          // called are no more
          version = data.version;
          ownerId = data.ownerId;
          fileId = data.fileId;
          userOwnerId = data.userOwnerId;
          clientId = data.clientId;
        } on FormatException catch (_) {
          request.response.statusCode = 422;
          await request.response.close();
          return;
        }
      }

      // Attempt to upgrade the HTTP connection to a web socket
      try {
        var ws = await WebSocketTransformer.upgrade(request);

        String key = _isolateKey(ownerId, fileId);
        var isolate = _isolates[key];
        if (isolate == null) {
          isolate = CoopIsolate(this, ownerId, fileId);
          // Immediately make it available...
          _isolates[key] = isolate;
          if (!await isolate.spawn(handler, options)) {
            log.severe('Unable to spawn isolate for file $key');
            await ws.close();
            return;
          }
        }
        if (!await isolate.addClient(userOwnerId, clientId, ws)) {
          log.severe('Unable to add client for file $key. '
              'This could be due to a previous shutdown attempt, check logs '
              'for indication of shutdown prior to this.');
          await ws.close();
        }
      } on WebSocketException catch (e) {
        log.severe('$e');
      }
    }, onError: (dynamic e) => log.severe('Error listening: $e'));
    return true;
  }

  /// Register the co-op server with the 2D service
  /// Returns true if registration is successful
  Future<bool> register();

  /// Deregisters the co-op server from the 2D service
  Future<bool> deregister();

  /// Pings the 2D service heartbeat endpoint
  void heartbeat();

  /// Validate this instance is an expected server for ownerId/fileId. We need to
  /// store a column with the assigned node for this file. Probably a
  /// server_index column in the Files table that maps to:
  ///
  /// wss://coop{server_index}.rive.app/{ownerId}/{fileId}
  /// wss://coop1.rive.app/34/10
  /// wss://coop2.rive.app/34/11
  ///
  /// There'll be a row locking stored procedure that'll grab a valid
  /// server_index for a file when it is first opened. This only runs if the
  /// server_index is currently null. server_index is reset to null when all
  /// clients have disconnected and some timeout elapses.
  ///
  /// Also take this opportunity to check that the token matches a valid user.
  Future<int> validate(
      HttpRequest request, int ownerId, int fileId, String token);
}

/// Wraps the data coming from the 2D service to initiate a web socket
/// connect with a client (proxied by the 2D service)
class WebSocketData {
  int version;
  int ownerId;
  int fileId;
  int userOwnerId;
  int clientId;

  WebSocketData.fromSegments(List<String> segments)
      : assert(segments.length == 6),
        assert(segments.first == 'proxy') {
    try {
      // Parse the version nr
      if (segments[1].length < 2) {
        log.severe('Invalid protocol version ${segments[1]}');
        throw const FormatException();
      }
      // Remove 'v' in 'v2'
      version = int.parse(segments[1].substring(1));
      if (version != protocolVersion) {
        log.severe('Client requests older protocal version nr: $version');
        throw const FormatException();
      }
      // Parse all the other segments, which should be ints
      ownerId = int.parse(segments[2]);
      fileId = int.parse(segments[3]);
      userOwnerId = int.parse(segments[4]);
      try {
        clientId = int.parse(segments[5]);
      } on FormatException catch (_) {
        log.severe('Invalid clientid: ${segments[5]}');
        // Don't rethrow, just give a default client id
        clientId = 0;
      }
    } on FormatException catch (e) {
      log.severe('Invalid message ${_segmentsToString(segments)}: $e');
      rethrow;
    }
  }

  @override
  String toString() => 'version: $version, '
      'ownerId: $ownerId'
      'fileId: $fileId'
      'userOwnerId: $userOwnerId'
      'clientId: $clientId';
}

// Prints out the raw segments data with no parsing
String _segmentsToString(List<String> segments) {
  final str = StringBuffer('segment[');
  for (var i = 0; i < segments.length; i++) {
    if (i == 0) {
      str.write('Type: ${segments[0]}');
    } else if (i == 1) {
      str.write('version: ${segments[1]}');
    } else if (i == 2) {
      str.write('ownerid: ${segments[2]}');
    } else if (i == 3) {
      str.write('fileid: ${segments[3]}');
    } else if (i == 4) {
      str.write('userOwnerId: ${segments[4]}');
    } else if (i == 5) {
      str.write('clientid: ${segments[5]}');
    } else {
      str.write('$i: ${segments[i]}');
    }
    if (i < segments.length - 1) {
      str.write(', ');
    }
  }
  str.write(']');
  return str.toString();
}
