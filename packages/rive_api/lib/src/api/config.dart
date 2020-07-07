/// API calls for the logged-in user

import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/data_model.dart';
import 'package:rive_api/model.dart';
import 'package:utilities/deserialize.dart';

final _log = Logger('Rive API Config');

class ConfigApi {
  ConfigApi([RiveApi api]) : api = api ?? RiveApi();
  final RiveApi api;

  Future<Config> appConfig() async {
    final res = await api.getFromPath('/api/config');

    try {
      final data = json.decodeMap(res.body);
      return Config.fromDM(ConfigDM.fromData(data));
    } on FormatException catch (e) {
      _log.severe('Error formatting app config api response: $e');
      rethrow;
    }
  }
}
