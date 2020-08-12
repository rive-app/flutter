/// API calls for a user's volumes

import 'dart:convert';
import 'package:http/http.dart';
import 'package:logging/logging.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/data_model.dart';
import 'package:utilities/deserialize.dart';

final _log = Logger('Rive API Volume');

class FolderApi {
  FolderApi([RiveApi api]) : api = api ?? RiveApi();
  final RiveApi api;

  Future<List<FolderDM>> folders(OwnerDM owner) async {
    if (owner is MeDM) {
      return myFolders(owner.ownerId);
    } else if (owner is TeamDM) {
      return teamFolders(owner.ownerId);
    } else {
      throw Exception('$owner must be either a team or a me');
    }
  }

  Future<List<FolderDM>> myFolders(int ownerId) async =>
      _folders('/api/my/files/folders', ownerId);

  Future<List<FolderDM>> teamFolders(int ownerId) async =>
      _folders('/api/teams/$ownerId/folders', ownerId);

  Future<List<FolderDM>> _folders(String path, int ownerId) async {
    final res = await api.getFromPath(path);
    try {
      final data = json.decodeMap(res.body);
      // Check that the user's signed in
      if (!data.containsKey('folders')) {
        _log.severe('Incorrectly formatted folders json response: $res.body');
        throw const FormatException(
            'Incorrectly formatted folders json response');
      }
      return FolderDM.fromDataList(data.getList('folders'), ownerId);
    } on FormatException catch (e) {
      _log.severe('Error formatting folder api response: $e');
      rethrow;
    }
  }

  Future<void> renameMyFolder(
      int ownerId, FolderDM folder, String newName) async {
    return _renameFolder('/api/my/files/folder', folder, newName);
  }

  Future<void> _renameFolder(
      String url, FolderDM folder, String newName) async {
    assert(newName != null && newName != '');
    String payload = json.encode({
      'name': newName,
      'order': folder.order,
      'parent': folder.parent,
      'id': folder.id
    });

    await api.post(api.host + url, body: payload);
  }

  Future<void> updateTeamFolder(int projectOwnerId, FolderDM folder,
      String newName, int newParentId) async {
    String payload = json.encode({
      'data': {'folderName': newName, 'folderParentId': newParentId}
    });
    return api.patch(
        api.host + '/api/projects/$projectOwnerId/folders/${folder.id}',
        body: payload);
  }

  Future<FolderDM> createPersonalFolder(int folderId, int ownerId) async {
    String payload =
        json.encode({'name': 'New Folder', 'order': 0, 'parent': folderId});

    var response =
        await api.post(api.host + '/api/my/files/folder', body: payload);
    return _parseFolderResponse(response, ownerId);
  }

  Future<FolderDM> createTeamFolder(
    int folderId,
    int projectId,
  ) async {
    String payload = json.encode({
      'data': {'folderName': 'New Folder'}
    });
    var response = await api.post(
        api.host + '/api/projects/$projectId/folders/$folderId',
        body: payload);
    return _parseFolderResponse(response, projectId);
  }

  FolderDM _parseFolderResponse(Response response, int ownerId) {
    if (response.statusCode == 200) {
      var folderResponse = json.decodeMap(response.body);
      return FolderDM.fromData(folderResponse, ownerId);
    }
    return null;
  }
}
