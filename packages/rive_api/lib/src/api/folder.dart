/// API calls for a user's volumes

import 'dart:convert';
import 'package:http/http.dart';
import 'package:logging/logging.dart';
import 'package:rive_api/src/api/api.dart';
import 'package:rive_api/src/data_model/data_model.dart';

final _log = Logger('Rive API Volume');

class FolderApi {
  FolderApi([RiveApi api]) : api = api ?? RiveApi();
  final RiveApi api;

  Future<List<FolderDM>> folders(OwnerDM owner) async {
    if (owner is MeDM) {
      return myFolders();
    } else if (owner is TeamDM) {
      return teamFolders(owner.ownerId);
    } else {
      throw Exception('$owner must be either a team or a me');
    }
  }

  Future<List<FolderDM>> myFolders() async => _folders('/api/my/files/folders');

  Future<List<FolderDM>> teamFolders(int ownerId) async =>
      _folders('/api/teams/$ownerId/folders');

  Future<List<FolderDM>> _folders(String path) async {
    final res = await api.getFromPath(path);
    try {
      final data = json.decode(res.body) as Map<String, Object>;
      // Check that the user's signed in
      if (!data.containsKey('folders')) {
        _log.severe('Incorrectly formatted folders json response: $res.body');
        throw FormatException('Incorrectly formatted folders json response');
      }
      return FolderDM.fromDataList(data['folders']);
    } on FormatException catch (e) {
      _log.severe('Error formatting folder api response: $e');
      rethrow;
    }
  }

  Future<FolderDM> createFolder(int folderId, [int teamId]) async {
    FolderDM newFolder;
    if (teamId != null) {
      newFolder = await _createTeamFolder(folderId, teamId);
    } else {
      newFolder = await _createFolder(folderId);
    }
    return newFolder;
  }

  Future<FolderDM> _createFolder(int folderId) async {
    String payload =
        json.encode({'name': 'New Folder', 'order': 0, 'parent': folderId});

    var response =
        await api.post(api.host + '/api/my/files/folder', body: payload);
    return _parseFolderResponse(response);
  }

  Future<FolderDM> _createTeamFolder(
    int folderId,
    int teamId,
  ) async {
    String payload = json.encode({
      'data': {'folderName': 'New Folder'}
    });
    var response = await api.post(
        api.host + '/api/teams/${teamId}/folders/${folderId}',
        body: payload);
    return _parseFolderResponse(response);
  }

  FolderDM _parseFolderResponse(Response response) {
    if (response.statusCode == 200) {
      var folderResponse = json.decode(response.body);
      return FolderDM.fromData(folderResponse);
    }
    return null;
  }
}
