/// API calls for a user's volumes

import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:rive_api/src/api/api.dart';
import 'package:rive_api/src/model/model.dart';

final _log = Logger('Rive API Volume');

class VolumeApi {
  VolumeApi() : api = RiveApi();
  final RiveApi api;

  Future<Iterable<Team>> get teams async {
    // Get the user's team volumes
    final res = await api.getFromPath('/api/teams');
    try {
      final data = json.decode(res.body) as List<dynamic>;
      return Team.fromDataList(data);
    } on FormatException catch (e) {
      _log.severe('Error formatting teams api response: $e');
      rethrow;
    }
  }

  Future<DirectoryTree> get directoryTreeMe async =>
      _directoryTree('/api/my/files/folders');

  Future<DirectoryTree> directoryTreeTeam(int id) async =>
      _directoryTree('/api/teams/$id/folders');

  Future<DirectoryTree> _directoryTree(String path) async {
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
