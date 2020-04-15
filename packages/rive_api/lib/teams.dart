import 'dart:convert';
import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:logging/logging.dart';

import 'package:rive_api/api.dart';
import 'package:rive_api/models/billing.dart';
import 'package:rive_api/models/team.dart';
import 'package:rive_api/models/user.dart';

final Logger log = Logger('Rive API');

/// Api for accessing the signed in users folders and files.
class RiveTeamsApi<T extends RiveTeam> {
  const RiveTeamsApi(this.api);
  final RiveApi api;

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
    Map<String, dynamic> data = json.decode(response.body);

    final team = RiveTeam.fromData(data);
    team.teamMembers = await getAffiliates(team.ownerId);

    return team;
  }

  /// GET /api/teams
  /// Returns the teams for the current user
  Future<List<T>> get teams async {
    var response = await api.get(api.host + '/api/teams');
    List<dynamic> data = json.decode(response.body);

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

    List<dynamic> data = json.decode(response.body);
    var teamUsers = data
        .map((userData) => RiveUser.asTeamMember(userData))
        .toList(growable: false);

    return teamUsers;
  }

  Future<RiveTeamBilling> getBillingInfo(int teamId) async {
    var response = await api.get(api.host + '/api/teams/$teamId/billing');
    dynamic data = json.decode(response.body);
    return RiveTeamBilling.fromData(data['data']);
  }

  Future<bool> updatePlan(
      int teamId, TeamsOption plan, BillingFrequency frequency) async {
    String payload = jsonEncode({
      'data': {'billingPlan': plan.name, 'billingCycle': frequency.name}
    });
    await api.put(api.host + '/api/teams/$teamId/billing', body: payload);
    return true;
  }

  Future<String> uploadAvatar(int teamId, String localUrl) async {
    ByteData bytes = await rootBundle.load(localUrl);

    var response = await api.post(api.host + '/api/teams/$teamId/avatar',
        body: bytes.buffer.asInt8List());
    Map<String, dynamic> data = json.decode(response.body);

    return data['url'];
  }

  /// Send a list of team invites to users
  Future<List<int>> sendInvites(
      int teamId, List<int> inviteIds, TeamRole permission) async {
    var response = <int>[];
    for (final ownerId in inviteIds) {
      int id = await sendInvite(teamId, ownerId, permission);
      if (id != null) {
        response.add(id);
      }
    }
    return response;
  }

  /// POST /api/teams/:team_owner_id/invite
  /// Sends a team invite to a user
  Future<int> sendInvite(int teamId, int ownerId, TeamRole permission) async {
    String payload = json.encode({
      'data': {
        'ownerId': ownerId,
        'permission': permission.name,
      }
    });
    await api.post('${api.host}/api/teams/$teamId/invite', body: payload);

    return ownerId;
  }
}
