/// API calls for a user's volumes

import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:rive_api/src/api/api.dart';
import 'package:rive_api/src/model/model.dart';

final _log = Logger('File Api');

class FileApi {
  FileApi() : api = RiveApi();
  final RiveApi api;

  Future<Iterable<File>> getFiles(Directory dir) async {
    // Get the user's team volumes
    final res = await api
        .get(api.host + '/api/teams/${dir.ownerId}/files/a-z/rive/${dir.id}');
    try {
      final data = json.decode(res.body) as List<int>;
      return File.fromIdList(data, dir.ownerId);
    } on FormatException catch (e) {
      _log.severe('Error formatting teams api response: $e');
      rethrow;
    }
  }

  Future<Iterable<File>> getFileDetails(
      Directory dir, List<int> fileIds) async {
    /// Fill in the details for the list of provided files (name, preview, etc).

    var res = await api.post(
      api.host + '/api/teams/${dir.ownerId}/files',
      body: jsonEncode(fileIds),
    );

    try {
      final data = json.decode(res.body) as List<dynamic>;
      return File.fromDataList(data);
    } on FormatException catch (e) {
      _log.severe('Error formatting teams api response: $e');
      rethrow;
    }
  }
}
