/// API calls for a user's volumes

import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:rive_api/src/api/api.dart';
import 'package:rive_api/src/data_model/data_model.dart';

final _log = Logger('File Api');

class FileApi {
  FileApi([RiveApi api]) : api = api ?? RiveApi();
  final RiveApi api;

  Future<List<FileDM>> getFiles(int folderId, {int ownerId = null}) async {
    // TODO: add sorting, and file type options one day.
    if (ownerId == null) {
      return myFiles(folderId);
    } else {
      return teamFiles(ownerId, folderId);
    }
  }

  Future<List<FileDM>> myFiles(int folderId) async =>
      _files('/api/my/files/a-z/rive/${folderId}');

  Future<List<FileDM>> teamFiles(int teamOwnerId, int folderId) async =>
      _files(
          '/api/teams/${teamOwnerId}/files/a-z/rive/${folderId}', teamOwnerId);

  Future<List<FileDM>> _files(String url, [int ownerId]) async {
    final res = await api.get(api.host + url);
    try {
      final data = json.decode(res.body) as List<dynamic>;
      return FileDM.fromIdList(data, ownerId);
    } on FormatException catch (e) {
      _log.severe('Error formatting teams api response: $e');
      rethrow;
    }
  }

  Future<List<FileDM>> getFileDetails(List<int> fileIds,
      {int ownerId = null}) async {
    if (ownerId == null) {
      return _myFileDetails(fileIds);
    } else {
      return _teamFileDetails(ownerId, fileIds);
    }
  }

  Future<List<FileDM>> _myFileDetails(List<int> fileIds) async =>
      _fileDetails('/api/my/files', fileIds);

  Future<List<FileDM>> _teamFileDetails(
          int teamOwnerId, List<int> fileIds) async =>
      _fileDetails('/api/teams/${teamOwnerId}/files', fileIds);

  Future<List<FileDM>> _fileDetails(String url, List fileIds) async {
    print(jsonEncode(fileIds));
    var res = await api.post(
      api.host + url,
      body: jsonEncode(fileIds),
    );

    try {
      final data = json.decode(res.body) as Map<String, dynamic>;
      final cdn = CdnDM.fromData(data['cdn']);
      return FileDM.fromDataList(data['files'], cdn);
    } on FormatException catch (e) {
      _log.severe('Error formatting teams api response: $e');
      rethrow;
    }
  }
}
