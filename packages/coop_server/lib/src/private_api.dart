import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:retry/retry.dart';

/// Timeout value for communication to the 2D service
const timeout = Duration(seconds: 5);

class ValidationResult {
  final int userId;
  final int ownerId;

  ValidationResult(this.userId, this.ownerId);
}

class SaveResult {
  final String key;
  final int revisionId;
  final int size;

  SaveResult(this.key, this.revisionId, this.size);
}

/// Communication to 2D server private API
///
class PrivateApi {
  final Logger log = Logger('CoopServer');

  /// 2D server end point host/url
  final String host =
      Platform.environment['PRIVATE_API'] ?? 'http://localhost:3003';

  /// Registers the co-op server with the 2D service.
  /// The 2D service will gather the co-op server's IP address
  /// from the inbound connection, so no need to explicitly pass
  /// it through.
  ///
  /// This will shut down the server if it is unable to register with
  /// the 2D server.
  Future<bool> register() async {
    try {
      final res = await retry(
        () => http.get('$host/coop/register').timeout(timeout),
        retryIf: (e) => e is SocketException || e is TimeoutException,
        onRetry: (e) => log.info('Unable to connect to 2D service @ $host', e),
      );
      if (res.statusCode != 200) {
        // Problem registering coop server; it's now orphaned
        // What to do?
        log.severe(
          'Error registering co-op server with 2D service: '
          'HTTP code ${res.statusCode}',
        );
        return false;
      }
    } on Exception catch (e) {
      log.severe('Exception registering co-op server with 2D service', e);
      return false;
    }
    return true;
  }

  /// Deregisters the co-op server with the 2D service.
  /// The 2D service will gather the co-op server's IP address
  /// from the inbound connection, so no need to explicitly pass
  /// it through.
  Future<bool> deregister() async {
    try {
      final res = await http.get('$host/coop/deregister').timeout(timeout);
      if (res.statusCode != 200) {
        // Problem deregistering coop server; it's now orphaned
        // What to do?
        log.severe(
          'Error deregistering co-op server with 2D service: '
          'HTTP code ${res.statusCode}',
        );
        return false;
      }
    } on Exception catch (e) {
      log.severe('Error deregistering co-op server with 2D service: $e');
      return false;
    }
    return true;
  }

  /// Pings the 2D service heartbeat endpoint
  void heartbeat() {
    try {
      http.get('$host/coop/heartbeat').timeout(timeout);
    } on Exception catch (e) {
      log.severe('Heartbeat ping to 2D service failed: $e');
    }
  }

  /// Validates that a user owns a file with a valid access token
  Future<ValidationResult> validate(
      int ownerId, int fileId, String token) async {
    try {
      var response = await http.get('$host/validate/$ownerId/$fileId/$token');
      if (response.statusCode == 200) {
        Map<String, dynamic> data;
        try {
          data = json.decode(response.body) as Map<String, dynamic>;
        } on FormatException catch (_) {
          return null;
        }

        return ValidationResult(
          data['userId'] is int ? data['userId'] as int : 0,
          data['ownerId'] is int ? data['ownerId'] as int : 0,
        );
      }
      return null;
    } on Exception catch (_) {
      return null;
    }
  }

  Future<SaveResult> save(int ownerId, int fileId, Uint8List data) async {
    try {
      var response =
          await http.post('$host/revise/$ownerId/$fileId', body: data);
      if (response.statusCode == 200) {
        Map<String, dynamic> data;
        try {
          data = json.decode(response.body) as Map<String, dynamic>;
        } on FormatException catch (_) {
          return null;
        }

        return SaveResult(
          data['key'] is String ? data['key'] as String : null,
          data['revision_id'] is int ? data['revision_id'] as int : 0,
          data['size'] is int ? data['size'] as int : 0,
        );
      }
      return null;
    } on Exception catch (_) {
      return null;
    }
  }

  Future<Uint8List> load(int ownerId, int fileId) async {
    try {
      var response = await http.get('$host/revision/$ownerId/$fileId');
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } on Exception catch (_) {
      return null;
    }
  }
}
