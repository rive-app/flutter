/// API calls for the logged-in user

import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:rive_api/src/api/api.dart';
import 'package:rive_api/src/data_model/data_model.dart';

final _log = Logger('Rive API Me');

class UserApi {
  UserApi([RiveApi api]) : api = api ?? RiveApi();
  final RiveApi api;

  Future<Iterable<UserDM>> search(String searchString) async {
    final res = await api.getFromPath(
        '/api/search/ac/avatar_artists/${Uri.encodeComponent(searchString)}');

    try {
      final data = json.decode(res.body) as List<dynamic>;
      return UserDM.fromSearchDataList(data);
    } on FormatException catch (e) {
      _log.severe('Error formatting whoami api response: $e');
      rethrow;
    }
  }
}
