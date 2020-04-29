/// API calls for the folders API

import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:rive_api/src/api/api.dart';
import 'package:rive_api/src/model/model.dart';

final _log = Logger('Rive API Directory Tree');

class DirectoryTreeApi {
  DirectoryTreeApi() : api = RiveApi();
  final RiveApi api;

  Future<DirectoryTree> directoryTree(Volume volume) async {
    var path = '/api/my/files/folders';
    if (volume.type == VolumeType.team) {
      path = '/api/teams/${volume.id}/folders';
    }
    final res = await api.getFromPath(path);
    try {
      final data = json.decode(res.body) as Map<String, dynamic>;
      // Check that the user's signed in
      if (data.containsKey('folders')) {
        _log.severe('Incorrectly formatted folders json response: $res.body');
        throw FormatException('Incorrectly formatted folders json response');
      }
      return DirectoryTree.fromFolderList(data['folders']);
    } on FormatException catch (e) {
      _log.severe('Error formatting folder api response: $e');
      rethrow;
    }
  }
}
