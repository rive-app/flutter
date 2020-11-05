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
import 'package:meta/meta.dart';

final _log = Logger('coop_server');

String _isolateKey(int fileId) => '$fileId';

abstract class CoopServer {
  final Map<String, CoopIsolate> _isolates = <String, CoopIsolate>{};

  CoopIsolateHandler get handler;
  HttpServer _server;

  int get editingFileCount => _isolates.keys.length;

  Iterable<CoopIsolate> get isolates => _isolates.values;

  int get clientCount =>
      _isolates.values.fold(0, (count, isolate) => count + isolate.clientCount);

  bool remove(CoopIsolate isolate) {
    return _isolates.remove(_isolateKey(isolate.fileId)) != null;
  }

  Future<bool> close() async {
    await _server.close(force: true);
    return true;
  }

  /// Allow implementations to override the isolate process interface.
  @protected
  CoopIsolate makeIsolateInterface(int fileId) => CoopIsolate(this, fileId);

  /// Listen for incoming connections and upgrade them to web sockets if valid
  /// This is assumed to be coming from a trusted source and so no user
  /// permissions will be checked here. This should only be called inside a
  /// private network.
  Future<bool> listen({int port = 8000, Map<String, String> options}) async {
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    } on Exception catch (e, s) {
      _log.severe('Unable to bind port to http server', e, s);
      return false;
    }
    _log.info('Listening on ${InternetAddress.anyIPv4}:$port');
    _server.listen((HttpRequest request) async {
      var segments = request.requestedUri.pathSegments;

      // If there are not 4 segments, return health status
      if (segments.length != 4) {
        request.response.statusCode = 200;
        request.response.write('Healthy');
        await request.response.close();
        return;
      }
      // Web socket request from the 2D service
      // This replaces the code for parsing segments of length 5
      // when the co-op server moves inside the VPC
      // The format expected is:
      // 'v<version>/<fileId>/<userOwnerId>/<clientId>
      try {
        _log.finest('Web socket request');
        final data = WebSocketData.fromSegments(segments);

        // Attempt to upgrade the HTTP connection to a web socket
        var ws = await WebSocketTransformer.upgrade(request);

        if (data.version != protocolVersion) {
          _log.info('Client connected with version ${data.version} server is '
              '$protocolVersion');
          await ws.close(
              1011, 'Unsupported Coop protocol version ${data.version}.');
          return;
        }

        String key = _isolateKey(data.fileId);
        var isolate = _isolates[key];
        if (isolate == null) {
          isolate = makeIsolateInterface(data.fileId);
          // Immediately make it available...
          _isolates[key] = isolate;
          if (!await isolate.spawn(handler, options)) {
            _isolates.remove(key);
            _log.severe('Unable to spawn isolate for file $key');
            await ws.close();
            return;
          }
        }
        if (!await isolate.addClient(data.userOwnerId, data.clientId, ws)) {
          _log.severe('Unable to add client for file $key. '
              'This could be due to a previous shutdown attempt, check logs '
              'for indication of shutdown prior to this.');
          await ws.close();
        }
      } on WebSocketException catch (e, s) {
        _log.severe('Failed to upgrade to web socket', e, s);
      } on FormatException catch (e, s) {
        _log.severe('Error parsing web socket request', e, s);
        request.response.statusCode = 422;
        await request.response.close();
      }
    }, onError: (dynamic e) => _log.severe('Error listening', e));
    return true;
  }

  /// Register the co-op server with the 2D service
  /// Returns true if registration is successful
  Future<bool> register();

  /// Deregisters the co-op server from the 2D service
  Future<bool> deregister();

  /// Pings the 2D service heartbeat endpoint
  void heartbeat();
}

/// Wraps the data coming from the 2D service to initiate a web socket
/// connect with a client (proxied by the 2D service)
class WebSocketData {
  int version;
  int fileId;
  int userOwnerId;
  int clientId;

  WebSocketData.fromSegments(List<String> segments)
      : assert(segments.length == 4) {
    try {
      // Parse the version nr
      if (segments[0].length < 2) {
        _log.severe('Invalid protocol version ${segments[0]}');
        throw const FormatException();
      }
      // Remove 'v' in 'v2'
      version = int.parse(segments[0].substring(1));
      // Parse all the other segments, which should be ints
      fileId = int.parse(segments[1]);
      userOwnerId = int.parse(segments[2]);
      try {
        clientId = int.parse(segments[3]);
      } on FormatException catch (e, s) {
        _log.severe('Invalid clientid: ${segments[3]}', e, s);
        // Don't rethrow, just give a default client id
        clientId = 0;
      }
    } on FormatException catch (e, s) {
      _log.severe('Invalid message ${_segmentsToString(segments)}', e, s);
      rethrow;
    }
  }

  @override
  String toString() => 'version: $version, '
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
      str.write('fileid: ${segments[2]}');
    } else if (i == 3) {
      str.write('userOwnerId: ${segments[3]}');
    } else if (i == 4) {
      str.write('clientid: ${segments[4]}');
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
