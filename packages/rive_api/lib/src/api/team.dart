/// API calls for a user's volumes

import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:rive_api/src/api/api.dart';
import 'package:rive_api/src/data_model/data_model.dart';

final _log = Logger('Rive API Volume');

class TeamApi {
  TeamApi([RiveApi api]) : api = api ?? RiveApi();
  final RiveApi api;

  Future<Iterable<TeamDM>> get teams async {
    // Get the user's team volumes
    final res = await api.getFromPath('/api/teams');
    try {
      final data = json.decode(res.body) as List<dynamic>;
      return TeamDM.fromDataList(data);
    } on FormatException catch (e) {
      _log.severe('Error formatting teams api response: $e');
      rethrow;
    }
  }
}
