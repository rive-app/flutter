import 'dart:convert';
import 'dart:core';

import 'package:rive_api/models/team.dart';
import 'package:logging/logging.dart';

import 'api.dart';

/// Api for accessing the signed in users folders and files.
abstract class RiveTeamsApi<T extends RiveTeam> {
  final RiveApi api;
  final Logger log = Logger('Rive API');
  RiveTeamsApi(this.api);

  // /api/teams
  Future<T> createTeam(teamName) async {
    String payload = jsonEncode({
      "data": {"teamName": teamName}
    });
    var response = await api.post(api.host + '/api/teams', body: payload);
    if (response.statusCode != 200) {
      // Todo: some form of error handling? also whats wrong with our error logging :D
      var message = 'Could not create new team ${response.body}';
      log.severe(message);
      print(message);
      return null;
    }
    Map<String, dynamic> data;
    try {
      data = json.decode(response.body) as Map<String, dynamic>;
    } on FormatException catch (_) {
      return null;
    }
    return RiveTeam.fromData(data);
  }
}
