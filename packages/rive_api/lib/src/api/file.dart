/// API calls for a user's volumes

import 'dart:convert';

import 'package:http/http.dart';
import 'package:logging/logging.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/data_model.dart';
import 'package:utilities/deserialize.dart';

final _log = Logger('File Api');

class FileApi {
  FileApi([RiveApi api]) : api = api ?? RiveApi();
  final RiveApi api;

  Future<List<FileDM>> recentFiles() async => _files('/api/files/ids/recent');

  Future<List<FileDM>> files(int ownerId, int folderId) {
    String route;
    switch (folderId) {
      case FolderDM.allId:
        route = '/api/files/ids/$ownerId/recent';
        break;
      case FolderDM.trashId:
        route = '/api/trash/ids/$ownerId/recent';
        break;

      default:
        route = '/api/files/ids/$ownerId/$folderId/recent';
        break;
    }
    return _files(route, ownerId);
  }

  Future<void> deleteFiles(List<int> fileIds, List<int> folderIds) async {
    return _deleteFiles('/api/files', fileIds, folderIds);
  }

  Future<void> _deleteFiles(
      String url, List<int> fileIds, List<int> folderIds) async {
    var payload = <String, List<int>>{
      'files': fileIds ?? [],
      'folders': folderIds ?? [],
    };
    await api.delete(api.host + url, body: jsonEncode(payload));
  }

  Future<List<FileDM>> _files(String url, [int ownerId]) async {
    final res = await api.get(api.host + url);
    try {
      final data = json.decodeList<int>(res.body);

      return FileDM.fromIdList(data, ownerId);
    } on FormatException catch (e) {
      _log.severe('Error formatting teams api response', e);
      rethrow;
    }
  }

  Future<List<FileDM>> fileDetails(List<int> fileIds) async =>
      _fileDetails('/api/files/details', fileIds);

  Future<List<FileDM>> _fileDetails(String url, List fileIds) async {
    var res = await api.post(
      api.host + url,
      body: jsonEncode(fileIds),
    );

    try {
      final data = json.decodeMap(res.body);
      final cdn = CdnDM.fromDataMap(data.getMap<String, dynamic>('cdn'));
      return FileDM.fromDataList(data.getList('files'), cdn);
    } on FormatException catch (e) {
      _log.severe('Error formatting teams api response', e);
      rethrow;
    }
  }

  /// This is a hack, kill me soon.
  Future<int> teamIdFromProjectId(int maybeProjectId) async {
    final res = await api.get('${api.host}/api/projects/$maybeProjectId/team');

    try {
      return int.tryParse(res.body);
    } on FormatException catch (e) {
      _log.severe('Error formatting teamIdFromProjectId response', e);
    }
    return 0;
  }

  Future<FileDM> createFile(int ownerId, int folderId) async {
    return _createFile(ownerId, folderId);
  }

  Future<bool> renameFile(int fileId, String name) async {
    return _renameFile(api.host + '/api/files/$fileId/name', name);
  }

  Future<bool> _renameFile(String url, String name) async {
    assert(name != null);
    String payload = json.encode({'name': name});
    var response = await api.post(url, body: payload);
    return response.statusCode == 200;
  }

  Future<FileDM> _createFile(int ownerId, int folderId) async {
    var response = await api.post(api.host +
        (folderId == null || folderId < 0
            ? '/api/files/$ownerId/create'
            : '/api/files/$ownerId/create/$folderId'));
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

  /// Find the socket server url to connect to for a specific file.
  Future<CoopConnectionInfo> establishCoop() async {
    if (api.host.indexOf('https://') == 0) {
      return CoopConnectionInfo(
          'wss://${api.host.substring('https://'.length)}/ws/proxy');
    } else if (api.host.indexOf('http://') == 0) {
      return CoopConnectionInfo(
          'ws://${api.host.substring('http://'.length)}/ws/proxy');
    }
    return null;
  }
}

class CoopConnectionInfo {
  final String socketHost;

  CoopConnectionInfo(this.socketHost);
}
