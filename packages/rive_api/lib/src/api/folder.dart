/// API calls for a user's volumes

import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:rive_api/src/api/api.dart';
import 'package:rive_api/src/data_model/data_model.dart';

final _log = Logger('Rive API Volume');

class FolderApi {
  FolderApi([RiveApi api]) : api = api ?? RiveApi();
  final RiveApi api;

  Future<Iterable<FolderDM>> folders(OwnerDM owner) async {
    if (owner is MeDM) {
      return _myFolders();
    } else if (owner is TeamDM) {
      return _teamFolders(owner);
    } else {
      throw Exception('$owner must be either a team or a me');
    }
  }

  Future<Iterable<FolderDM>> _myFolders() async =>
      _folders('/api/my/files/folders');

  Future<Iterable<FolderDM>> _teamFolders(TeamDM team) async =>
      _folders('/api/teams/${team.ownerId}/folders');

  Future<Iterable<FolderDM>> _folders(String path) async {
    final res = await api.getFromPath(path);
    try {
      final data = json.decode(res.body) as Map<String, dynamic>;
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
}
