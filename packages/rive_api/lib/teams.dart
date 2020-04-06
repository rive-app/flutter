import 'dart:convert';
import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/models/billing.dart';
import 'package:rive_api/models/team.dart';
import 'package:rive_api/models/user.dart';

/// Api for accessing the signed in users folders and files.
class RiveTeamsApi<T extends RiveTeam> {
  final RiveApi api;
  final Logger log = Logger('Rive API');
  RiveTeamsApi(this.api);

  /// POST /api/teams
  Future<T> createTeam(
      {@required String teamName,
      @required String plan,
      @required String frequency}) async {
    String payload = jsonEncode({
      "data": {
        "name": teamName,
        "username": teamName,
        "billingPlan": plan,
        "billingCycle": frequency
      }
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
    final team = RiveTeam.fromData(data);
    team.teamMembers = await getAffiliates(team.ownerId);

    return team;
  }

  /// GET /api/teams
  /// Returns the teams for the current user
  Future<List<T>> get teams async {
    var response = await api.get(api.host + '/api/teams');
    if (response.statusCode != 200) {
      // Todo: some form of error handling? also whats wrong with our error logging :D
      var message = 'Could not get teams ${response.body}';
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
    var teams = RiveTeam.fromDataList(data);
    for (final team in teams) {
      team.teamMembers = await getAffiliates(team.ownerId);
    }
    return teams;
  }

  /// GET /api/teams/<team_id>/affiliates
  /// Returns the teams for the current user
  Future<List<RiveUser>> getAffiliates(int teamId) async {
    var response = await api.get(api.host + '/api/teams/$teamId/affiliates');
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
    var teamUsers = data
        .map((userData) => RiveUser.asTeamMember(userData))
        .toList(growable: false);

    return teamUsers;
  }

  Future<RiveTeamBilling> getBillingInfo(int teamId) async {
    var response = await api.get(api.host + '/api/teams/$teamId/billing');
    if (response.statusCode != 200) {
      // Todo: some form of error handling? also whats wrong with our error logging :D
      var message = 'Could not create new team ${response.body}';
      log.severe(message);
      print(message);
      return null;
    }

    print("Got my data! ${response.body}");
    dynamic data;
    try {
      data = json.decode(response.body);
    } on FormatException catch (e) {
      log.severe('Unable to parse response from server: $e');
    }
    return RiveTeamBilling.fromData(data['data']);
  }

  Future<bool> updatePlan(
      int teamId, TeamsOption plan, BillingFrequency frequency) async {
    String payload = jsonEncode({
      'data': {'billingPlan': plan.name, 'billingCycle': frequency.name}
    });
    var response =
        await api.put(api.host + '/api/teams/$teamId/billing', body: payload);
    if (response.statusCode != 200) {
      var message = 'Could not create new team ${response.body}';
      log.severe(message);
      print(message);
      return null;
    }
    return true;
  }
}
