/// API calls for a user's volumes

import 'dart:convert';
import 'package:http/http.dart';
import 'package:logging/logging.dart';
import 'package:rive_api/src/api/api.dart';
import 'package:rive_api/src/data_model/data_model.dart';

final _log = Logger('File Api');

class FileApi {
  FileApi([RiveApi api]) : api = api ?? RiveApi();
  final RiveApi api;

  Future<List<FileDM>> myFiles(int ownerId, int folderId) async =>
      _files('/api/my/files/a-z/rive/${folderId}', ownerId);

  Future<List<FileDM>> teamFiles(int ownerId, int folderId) async =>
      _files('/api/teams/${ownerId}/files/a-z/rive/${folderId}', ownerId);

  Future<List<FileDM>> _files(String url, [int ownerId]) async {
    final res = await api.get(api.host + url);
    try {
      final data = json.decode(res.body) as List<Object>;
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
      _fileDetails('/api/teams/${teamOwnerId}/files', fileIds, teamOwnerId);

  Future<List<FileDM>> _fileDetails(String url, List fileIds,
      [int ownerIdOverride]) async {
    // TODO: ownerIdOverride deals with Projects vs Teams.

    var res = await api.post(
      api.host + url,
      body: jsonEncode(fileIds),
    );

    try {
      final data = json.decode(res.body) as Map<String, Object>;
      final cdn = CdnDM.fromData(data['cdn']);
      return FileDM.fromDataList(data['files'], cdn, ownerIdOverride);
    } on FormatException catch (e) {
      _log.severe('Error formatting teams api response: $e');
      rethrow;
    }
  }

  Future<FileDM> createFile(int folderId, [int teamId]) async {
    FileDM newFile;
    if (teamId != null) {
      newFile = await _createTeamFile(folderId, teamId);
    } else {
      newFile = await _createFile(folderId);
    }
    return newFile;
  }

  // /api/my/files/:product/create/:folder_id?
  Future<FileDM> _createFile(int folderId) async {
    var response =
        await api.post(api.host + '/api/my/files/rive/create/$folderId');
    return _parseFileResponse(response);
  }

  Future<FileDM> _createTeamFile(
    int folderId,
    int teamId,
  ) async {
    String payload = json.encode({
      'data': {'fileName': 'New File'}
    });
    var response = await api.post(
        api.host + '/api/teams/${teamId}/folders/${folderId}/new/rive/',
        body: payload);
    return _parseFileResponse(response);
  }

  FileDM _parseFileResponse(Response response) {
    // Team response
    // {"file":{"id":1,"oid":40846,"name":"New File","route":"/a/null/files/rive/new-file","product":"rive"},"reroute":"/a/null/files/rive/new-file"}

    if (response.statusCode != 200) {
      return null;
    }
    Map<String, dynamic> data;
    try {
      data = json.decode(response.body) as Map<String, dynamic>;
    } on FormatException catch (_) {
      return null;
    }
    dynamic fileData = data['file'];
    if (fileData is Map<String, dynamic>) {
      return FileDM.fromCreateData(fileData);
    }
    return null;
  }
}
