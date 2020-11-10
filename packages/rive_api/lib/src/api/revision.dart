import 'dart:convert';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/src/model/revision.dart';
import 'package:utilities/deserialize.dart';

final _log = Logger('Revision Api');

class RevisionApi {
  RevisionApi({
    RiveApi api,
    this.fileId,
  })  : api = api ?? RiveApi(),
        urlBase = '/api/files/$fileId/';

  final RiveApi api;
  final int fileId;

  final String urlBase;

  /// List the revisions for this file.
  Future<List<RevisionDM>> list() async {
    final res = await api.get(api.host + urlBase + 'revisions');
    try {
      final data = json.decodeMap(res.body);
      return RevisionDM.fromDataList(
          data.getList<Map<String, dynamic>>('revisions'));
    } on FormatException catch (e) {
      _log.severe('Error formatting teams api response', e);
      rethrow;
    }
  }

  /// Get the contents of a revision.
  Future<Uint8List> contents(RevisionDM revision) async {
    final res = await api.get('${api.host}/api/revisions/${revision.key}');
    return res.bodyBytes;
  }
}
