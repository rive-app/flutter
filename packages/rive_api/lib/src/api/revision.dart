import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/src/model/revision.dart';
import 'package:utilities/deserialize.dart';

final _log = Logger('Revision Api');

class RevisionApi {
  //revisionsReq.open("GET", "/api/files/" + this.context.nima.file.owner.id + "/" + this.context.nima.file.id + "/revisions", true);
  RevisionApi({
    RiveApi api,
    this.ownerId,
    this.fileId,
  })  : api = api ?? RiveApi(),
        urlBase = '/api/files/$ownerId/$fileId/';

  final RiveApi api;
  final int ownerId, fileId;

  final String urlBase;

  Future<List<RevisionDM>> list() async {
    final res = await api.get(api.host + urlBase + 'revisions');
    try {
      final data = json.decodeMap(res.body);
      return RevisionDM.fromDataList(
          data.getList<Map<String, dynamic>>('revisions'));
    } on FormatException catch (e) {
      _log.severe('Error formatting teams api response: $e');
      rethrow;
    }
  }
}
