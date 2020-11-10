import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:core/coop/change.dart';
import 'package:core/coop/coop_command.dart';
import 'package:core/coop/coop_file.dart';
import 'package:core/coop/coop_server_client.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:retry/retry.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

/// Timeout value for communication to the 2D service
const timeout = Duration(seconds: 5);

class SaveResult {
  final String key;
  final int revisionId;
  final int size;

  SaveResult(this.key, this.revisionId, this.size);
}

/// Communication to 2D server private API
///
class PrivateApi {
  final log = Logger('CoopServer');
  final Uri _uri;
  String get origin => _uri.origin;
  String get authority => _uri.authority;

  // host is either host, the env variable, or localhost:3003
  PrivateApi({String host})
      : _uri = Uri.parse(host ??
            Platform.environment['PRIVATE_API'] ??
            'http://localhost:3003');

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
        () => http.get('$origin/coop/register').timeout(timeout),
        retryIf: (e) => e is SocketException || e is TimeoutException,
        onRetry: (e) =>
            log.info('Unable to connect to 2D service @ $origin', e),
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
    } on Exception catch (e, s) {
      log.severe('Exception registering co-op server with 2D service', e, s);
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
      final res = await http.get('$origin/coop/deregister').timeout(timeout);
      if (res.statusCode != 200) {
        // Problem deregistering coop server; it's now orphaned
        // What to do?
        log.severe(
          'Error deregistering co-op server with 2D service: '
          'HTTP code ${res.statusCode}',
        );
        return false;
      }
    } on Exception catch (e, s) {
      log.severe('Error deregistering co-op server with 2D service:', e, s);
      return false;
    }
    return true;
  }

  /// Pings the 2D service heartbeat endpoint
  void heartbeat([Map<String, String> data]) {
    try {
      http.get(Uri.http(authority, '/coop/heartbeat', data)).timeout(timeout);
    } on Exception catch (e) {
      log.severe('Heartbeat ping to 2D service failed: $e');
    }
  }

  Future<SaveResult> save(int fileId, Uint8List data) async {
    try {
      var response =
          await http.post('$origin/revise/$fileId', body: data);
      if (response.statusCode == 200) {
        Map<String, dynamic> data;
        try {
          data = json.decode(response.body) as Map<String, dynamic>;
        } on FormatException catch (e, s) {
          log.severe(
              'Error parsing json saving a revision update for '
              'file: $fileId ',
              e,
              s);
          return null;
        }

        return SaveResult(
          data['key'] is String ? data['key'] as String : null,
          data['revision_id'] is int ? data['revision_id'] as int : 0,
          data['size'] is int ? data['size'] as int : 0,
        );
      }
      return null;
    } on Exception catch (e, s) {
      log.severe(
          'Error saving a revision update for '
          'file: $fileId ',
          e,
          s);
      return null;
    }
  }

  /// Load the latest revision data for a file.
  Future<Uint8List> load(int fileId) async {
    print('loading $fileId');
    try {
      var response = await http.get('$origin/revision/$fileId');
      if (response.statusCode == 200) {
        print('good!');
        return response.bodyBytes;
      }
      print('got ${response.statusCode}');
      return null;
    } on Exception catch (e, s) {
      log.severe(
          'Error loading a revision '
          'file: $fileId, ',
          e,
          s);
      return null;
    }
  }

  /// Restore a revision by id for a file, and get the data for it.
  Future<Uint8List> restoreRevision(
      int fileId, int revisionId) async {
    print('restoring revision $fileId $revisionId');
    try {
      var response =
          await http.post('$origin/revision/$fileId/$revisionId');
      if (response.statusCode == 200) {
        print('revision restored $fileId $revisionId');
        return response.bodyBytes;
      }
      return null;
    } on Exception catch (e, s) {
      log.severe(
          'Error restoring a revision for '
          'file: $fileId, '
          'revision: $revisionId ',
          e,
          s);
      return null;
    }
  }

  Future<void> persistChangeSet(CoopServerClient client, CoopFile file,
      int serverChangeId, ChangeSet changes, bool accepted) async {
    try {
      var writer = BinaryWriter(alignment: 8 * changes.numProperties);
      changes.serialize(writer);

      var response = await http.post(
        '$origin/changeset/${file.fileId}/${serverChangeId - CoopCommand.minChangeId}?userId=${client.ownerId.toString()}&accepted=${accepted ? 'true' : 'false'}',
        body: writer.uint8Buffer,
      );
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } on Exception catch (e, s) {
      log.severe(
          'Error persisting change set for '
          'file: ${file.fileId}, '
          'serverChangeId: $serverChangeId '
          'minChangeId: ${CoopCommand.minChangeId} ',
          e,
          s);
    }
  }
}
