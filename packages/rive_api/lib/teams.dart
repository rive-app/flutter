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

  /// POST /api/teams
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
    } on FormatException catch (e) {
      log.severe('Unable to parse response from server: $e');
    }
    return RiveTeam.fromData(data);
  }

  /// GET /api/teams
  /// Returns the teams for the current user
  Future<List<T>> get teams async {
    var response = await api.get(api.host + '/api/teams');
    if (response.statusCode != 200) {
      // Todo: some form of error handling? also whats wrong with our error logging :D
      var message = 'Could not create new team ${response.body}';
      log.severe(message);
      print(message);
      return null;
    }
    List<dynamic> data;
    try {
      data = json.decode(response.body);
    } on FormatException catch (e) {
      log.severe('Unable to parse response from server: $e');
    }
    print('TEAMS SERVER BODY: ${response.body}');
    return RiveTeam.fromDataList(data);
  }

  // PUT /api/teams/teamId
  Future<void> updateTeamInfo(
    teamId, {
    String name,
    String username,
    String location,
    String website,
    String bio,
    String twitter,
    String instagram,
    bool isForHire,
  }) async {
    String payload = jsonEncode({
      'data': {
        'teamName': name,
        'teamUsername': username,
        'location': location,
        'website': website,
        'blurb': bio,
        'twitter': twitter,
        'instagram': instagram,
      }
    });
    var response =
        await api.put(api.host + '/api/teams/$teamId', body: payload);
    if (response.statusCode != 200) {
      // Todo: some form of error handling? also whats wrong with our error logging :D
      var message = 'Could not create new team ${response.body}';
      log.severe(message);
      print(message);
      return null;
    }
  }
}
