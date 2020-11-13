import 'dart:convert';
import 'dart:core';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/models/billing.dart';
import 'package:rive_api/models/team.dart';
import 'package:rive_api/models/team_role.dart';
import 'package:rive_api/models/user.dart';
import 'package:utilities/deserialize.dart';

final Logger log = Logger('Rive API');

/// Api for accessing the signed in users folders and files.
class RiveTeamsApi<T extends RiveTeam> {
  const RiveTeamsApi(this.api);
  final RiveApi api;

  /// POST /api/teams
  Future<RiveTeam> createTeam(
      {@required String teamName,
      @required String plan,
      @required String frequency,
      @required String stripeToken}) async {
    String payload = jsonEncode({
      'data': {
        'name': teamName,
        'username': teamName,
        'billingPlan': plan,
        'billingCycle': frequency,
        'billingToken': stripeToken
      }
    });
    var response = await api.post(api.host + '/api/teams', body: payload);
    final data = json.decodeMap(response.body);

    final team = RiveTeam.fromData(data);
    team.teamMembers = await getAffiliates(team.ownerId);

    return team;
  }

  Future<bool> checkName({@required String teamName}) async {
    String payload = jsonEncode({
      'data': {
        'username': teamName,
      }
    });
    try {
      await api.post(api.host + '/api/teams/namecheck', body: payload);
      return true;
    } on ApiException {
      return false;
    }
  }

  /// GET /api/teams
  /// Returns the teams for the current user
  Future<List<RiveTeam>> get teams async {
    var response = await api.get(api.host + '/api/teams');
    final data = json.decodeList<Map<String, dynamic>>(response.body);

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

    final data = json.decodeList<Map<String, dynamic>>(response.body);
    var teamUsers = data
        .map((userData) => RiveUser.asTeamMember(userData))
        .toList(growable: false);

    return teamUsers;
  }

  /// Retrieves for the team w/ [teamId]:
  /// - plan type (studio/org)
  /// - billing cycle (monthly/yearly)
  /// - is plan canceled
  /// - CC brand
  /// - CC last 4 digits
  /// - CC expiry
  /// - Next payment date
  Future<RiveTeamBilling> getBillingInfo(int teamId) async {
    var response = await api.get(api.host + '/api/teams/$teamId/billing');
    final data = json.decodeMap(response.body);
    return RiveTeamBilling.fromData(data.getMap<String, Object>('data'));
  }

  Future<bool> updatePlan(
      int teamId, TeamsOption plan, BillingFrequency frequency) async {
    try {
      String payload = jsonEncode({
        'data': {'billingPlan': plan.name, 'billingCycle': frequency.name}
      });
      await api.put(api.host + '/api/teams/$teamId/billing', body: payload);
      return true;
    } on ApiException catch (err) {
      var response = err.response;
      log.severe('[Error] updatePlan()\n${response.body}');
      return false;
    }
  }

  Future<String> uploadAvatar(int teamId, Uint8List bytes) async {
    var response =
        await api.post(api.host + '/api/teams/$teamId/avatar', body: bytes);
    final data = json.decodeMap(response.body);

    return data.getString('url');
  }

  /// Send a list of team invites to users
  Future<bool> sendInvites(
    int teamOwnerId,
    TeamRole permission,
    Set<int> userInvites,
    Set<String> emailInvites,
  ) async {
    for (final ownerId in userInvites) {
      bool success = await sendInvite(
        teamOwnerId,
        permission,
        ownerId: ownerId,
      );
      if (!success) {
        // Early out.
        return false;
      }
    }
    for (final email in emailInvites) {
      bool success = await sendInvite(
        teamOwnerId,
        permission,
        email: email,
      );
      if (!success) {
        // Early out.
        return false;
      }
    }
    return true;
  }

  /// POST /api/teams/:team_owner_id/invite
  /// Sends a team invite to a user or an email address;
  Future<bool> sendInvite(
    int teamId,
    TeamRole permission, {
    int ownerId,
    String email,
  }) async {
    final payload = <String, Object>{
      'permission': permission.name,
    };

    if (ownerId != null) {
      payload['ownerId'] = ownerId;
    }
    if (email != null) {
      payload['email'] = email;
    }
    try {
      await api.post(
        '${api.host}/api/teams/$teamId/invite',
        body: json.encode(payload),
      );
      return true;
    } on ApiException catch (apiException) {
      final response = apiException.response;
      var message = 'Could not send invite ${response.body}';
      log.severe(message);
      return false;
    }
  }

  /// PATCH /api/teams/:team_owner_id/renew
  /// If [renew] is [false] the plan will be canceled.
  /// Otherwise it'll be set for renewal.
  Future<bool> renewPlan(int teamId, bool renew) async {
    try {
      String payload = jsonEncode({'renew': renew});
      await api.patch('${api.host}/api/teams/$teamId/renew', body: payload);
      return true;
    } on ApiException catch (apiException) {
      final response = apiException.response;
      var message = '[Error] renewPlan()\n${response.body}';
      log.severe(message);
      return false;
    }
  }

  /// POST /api/teams/:team_owner_id/retry_payment
  Future<bool> retryPayment(int teamId) async {
    try {
      await api.post('${api.host}/api/teams/$teamId/retry_payment');
      return true;
    } on ApiException catch (apiException) {
      final response = apiException.response;
      var message = '[Error] retryPayment()\n${response.body}';
      log.severe(message);
      return false;
    }
  }

  /// POST /api/teams/:team_owner_id/feedback
  /// On plan cancelation, send feedback from user with [ownerId]
  Future<bool> sendFeedback(
    int teamId,
    String feedback,
    String note,
  ) async {
    try {
      String payload = jsonEncode({
        'feedback': feedback,
        if (note != null) 'note': note,
      });
      await api.post('${api.host}/api/teams/$teamId/feedback', body: payload);
      return true;
    } on ApiException catch (apiException) {
      final response = apiException.response;
      var message = '[Error] sendFeedback()\n${response.body}';
      log.severe(message);
      return false;
    }
  }
}
