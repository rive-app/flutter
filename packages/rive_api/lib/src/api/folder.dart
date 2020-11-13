/// API calls for a user's volumes

import 'dart:convert';
import 'package:http/http.dart';
import 'package:logging/logging.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/data_model.dart';
import 'package:utilities/deserialize.dart';

final _log = Logger('Rive API Folders');

class FolderApi {
  FolderApi([RiveApi api]) : api = api ?? RiveApi();
  final RiveApi api;

  Future<List<FolderDM>> folders(OwnerDM owner) async =>
      _folders('/api/folders/${owner.ownerId}', owner.ownerId);

  Future<List<FolderDM>> _folders(String path, int ownerId) async {
    final res = await api.getFromPath(path);
    try {
      final data = json.decodeList<Map<String, dynamic>>(res.body);
      // Check that the user's signed in
      return FolderDM.fromDataList(data, ownerId);
    } on FormatException catch (e) {
      _log.severe('Error formatting folder api response', e);
      rethrow;
    }
  }

  Future<void> updateFolder(
      FolderDM folder, String newName, int newParentId) async {
    String payload = json.encode({
      'name': newName,
      'parent': newParentId == null || newParentId < 0 ? null : newParentId,
      'order': 0,
    });
    return api.patch(api.host + '/api/folders/${folder.id}', body: payload);
  }

  Future<FolderDM> createFolder(int ownerId, [int folderId]) async {
    String payload = json.encode({
      'name': 'New Folder',
      'order': 0,
      'parent': folderId == null || folderId < 0 ? null : folderId,
    });

    var response =
        await api.post(api.host + '/api/folders/$ownerId', body: payload);
    return _parseFolderResponse(response, ownerId);
  }

  FolderDM _parseFolderResponse(Response response, int ownerId) {
    if (response.statusCode == 200) {
      var folderResponse = json.decodeMap(response.body);
      return FolderDM.fromData(folderResponse, ownerId);
    }
    return null;
  }
}
