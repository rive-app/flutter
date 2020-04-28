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
}
