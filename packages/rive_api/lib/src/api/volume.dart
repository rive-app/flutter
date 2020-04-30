/// API calls for a user's volumes

import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:rive_api/src/api/api.dart';
import 'package:rive_api/src/model/model.dart';

final _log = Logger('Rive API Volume');

class VolumeApi {
  VolumeApi() : api = RiveApi();
  final RiveApi api;

  Future<Iterable<Volume>> get volumes async {
    // Note the user's personal volume
    final me = await MeApi().whoami;
    final userVolume = Volume(name: me.name);
    // Get the user's team volumes
    final res = await api.getFromPath('/api/teams');
    try {
      final data = json.decode(res.body) as List<dynamic>;
      final teamVolumes = Volume.fromDataList(data);
      return []
        ..add(userVolume)
        ..addAll(teamVolumes);
    } on FormatException catch (e) {
      _log.severe('Error formatting teams api response: $e');
      rethrow;
    }
  }

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
