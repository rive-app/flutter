/// API calls for a user's volumes

import 'dart:convert';

import 'package:http/http.dart';
import 'package:logging/logging.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/data_model.dart';

final _log = Logger('File Api');
const specialFolderIds = {0, 1};

class FileApi {
  FileApi([RiveApi api]) : api = api ?? RiveApi();
  final RiveApi api;

  Future<List<FileDM>> myFiles(int ownerId, int folderId) async =>
      _files('/api/my/files/a-z/rive/${folderId}', ownerId);

  Future<List<FileDM>> teamFiles(int ownerId, int folderId) async =>
      _files('/api/teams/${ownerId}/files/a-z/rive/${folderId}', ownerId);

  Future<void> deleteMyFiles(List<int> fileIds, List<int> folderIds) async {
    return _deleteFiles('/api/my/files', fileIds, folderIds);
  }

  Future<void> deleteTeamFiles(
      int teamOwnerId, List<int> fileIds, List<int> folderIds) async {
    return _deleteFiles('/api/teams/${teamOwnerId}/files', fileIds, folderIds);
  }

  Future<void> _deleteFiles(
      String url, List<int> fileIds, List<int> folderIds) async {
    // TODO: changing input is pretty yuk.
    folderIds.removeWhere((folderId) => specialFolderIds.contains(folderId));
    var payload = <String, List<int>>{
      "files": fileIds ?? [],
      "folders": folderIds ?? [],
    };
    print(jsonEncode(payload));
    await api.delete(api.host + url, body: jsonEncode(payload));
  }

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

  Future<List<FileDM>> myFileDetails(List<int> fileIds) async =>
      _fileDetails('/api/my/files', fileIds);

  Future<List<FileDM>> teamFileDetails(
          List<int> fileIds, int teamOwnerId) async =>
      _fileDetails('/api/teams/${teamOwnerId}/files', fileIds);

  Future<List<FileDM>> _fileDetails(String url, List fileIds) async {
    var res = await api.post(
      api.host + url,
      body: jsonEncode(fileIds),
    );

    try {
      final data = json.decode(res.body) as Map<String, Object>;
      final cdn = CdnDM.fromData(data['cdn']);
      return FileDM.fromDataList(data['files'], cdn);
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

  Future<bool> renameMyFile(int ownerId, int fileId, String name) async {
    return _renameFile(api.host + '/api/files/$ownerId/$fileId/name', name);
  }

  Future<bool> renameTeamFile(int ownerId, int fileId, String name) async {
    return _renameFile(
        api.host + '/api/teams/$ownerId/files/$fileId/name', name);
  }

  Future<bool> _renameFile(String url, String name) async {
    assert(name != null);
    String payload = json.encode({'name': name});
    var response = await api.post(url, body: payload);
    return response.statusCode == 200;
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
