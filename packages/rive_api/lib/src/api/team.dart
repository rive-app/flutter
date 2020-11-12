/// API calls for a user's volumes

import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/data_model.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/models/team_role.dart';
import 'package:utilities/deserialize.dart';

final _log = Logger('Rive API Volume');

class TeamApi {
  TeamApi([RiveApi api]) : api = api ?? RiveApi();
  final RiveApi api;

  Future<Iterable<TeamDM>> get teams async {
    // Get the user's team volumes
    final res = await api.getFromPath('/api/teams');
    try {
      final data = json.decodeList<Map<String, dynamic>>(res.body);
      return TeamDM.fromDataList(data);
    } on FormatException catch (e) {
      _log.severe('Error formatting teams api response', e);
      rethrow;
    }
  }

  /// POST /api/teams
  Future<TeamDM> createTeam(String teamName, String plan, String frequency,
      String stripeToken) async {
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

    final team = TeamDM.fromData(data);

    return team;
  }

  Future<Iterable<TeamMemberDM>> teamMembers(int teamId) async {
    final res = await api.getFromPath('/api/teams/$teamId/affiliates');
    try {
      final data = json.decodeList<Map<String, Object>>(res.body);
      return TeamMemberDM.formDataList(data);
    } on FormatException catch (e) {
      _log.severe('Error formatting teams api response', e);
      rethrow;
    }
  }

  /// Accepts a team invite
  Future<void> acceptInvite(int teamId) async {
    await api.post('${api.host}/api/teams/$teamId/invite/accept');
  }

  /// Declines a team invite
  Future<void> declineInvite(int teamId) async {
    await api.post('${api.host}/api/teams/$teamId/invite/reject');
  }

  Future<bool> rescindInvite(int teamId, {int ownerId, String email}) async {
    String payload = json.encode({
      if (ownerId > 0) 'ownerId': ownerId,
      if (email != null) 'userEmail': email,
    });
    try {
      await api.delete('${api.host}/api/teams/$teamId/invite', body: payload);
      return true;
    } on ApiException catch (err) {
      log.severe('[Error] rescindInvite() ${err.response.body}');
      return false;
    }
  }

  Future<bool> updateInvite(
    int teamId,
    TeamRole role, {
    int ownerId,
    String email,
  }) async {
    final payloadMap = {
      if (ownerId != null) 'ownerId': ownerId,
      if (email != null) 'userEmail': email,
      'role': role.name
    };
    String payload = json.encode(payloadMap);
    try {
      await api.patch(
        '${api.host}/api/teams/$teamId/invite',
        body: payload,
      );
      return true;
    } on ApiException catch (err) {
      log.severe('[Error] updateInvite() ${err.response.body}');
      return false;
    }
  }

  /// GET /api/teams/<team_id>
  /// Returns the team's profile info.
  Future<ProfileDM> getProfile(int ownerId) async {
    final response = await api.get('${api.host}/api/teams/$ownerId');
    if (response.statusCode != 200) {
      var message = 'Could not get team info ${response.body}';
      log.severe(message);
      return null;
    }
    try {
      final data = json.decode(response.body) as Map<String, Object>;
      return ProfileDM.fromData(data);
    } on FormatException catch (e) {
      log.severe('Error formatting team profile response: $e');
      rethrow;
    }
  }

  // PUT /api/teams/<teamId>
  // This endpoint uploads the new profile info for this team.
  Future<bool> updateProfile(Team team, Profile profile) async {
    var teamId = team.ownerId;
    var response =
        await api.put(api.host + '/api/teams/$teamId', body: profile.encoded);
    if (response.statusCode != 200) {
      var message = 'Could not update team profile: ${response.body}';
      log.severe(message);
      return false;
    }
    return true;
  }

  Future<bool> removeFromTeam(int memberOwnerId, int teamId) async {
    try {
      await api.delete('${api.host}/api/teams/$teamId/members/$memberOwnerId');
      return true;
    } on ApiException catch (err) {
      log.severe('Failed to remove team member: ${err.response.body}');
      return false;
    }
  }

  Future<bool> changeRole(int teamId, int memberOwnerId, TeamRole role) async {
    try {
      await api.put(
          '${api.host}/api/teams/$teamId/members/$memberOwnerId/${role.name}');
      return true;
    } on ApiException catch (err) {
      log.severe('[Error] changeRole() ${err.response.body}');
      return false;
    }
  }

  /// PATCH /api/teams/:team_id/token
  /// Sends a new token for the current team to update the current payment
  /// method.
  Future<bool> saveToken(int teamId, String token) async {
    try {
      String payload = json.encode({'token': token});
      await api.patch(
        '${api.host}/api/teams/$teamId/token',
        body: payload,
      );
      return true;
    } on ApiException catch (err) {
      log.severe('[ERROR] saveToken() ${err.response.body}');
      return false;
    }
  }

  Future<BillingDetailsDM> getBillingHistory(int teamId) async {
    try {
      var response = await api.get('${api.host}/api/teams/$teamId/charges');
      final data = json.decodeMap(response.body);
      return BillingDetailsDM.fromData(data);
    } on ApiException catch (apiException) {
      final response = apiException.response;
      var message = '[ERROR] getReceiptDetails()\n${response.body}';
      log.severe(message);
      return null;
    }
  }

  Future<bool> setBillingDetails(int teamId, BillingDetails details) async {
    try {
      String payload = jsonEncode(<String, String>{
        'business_name': details.businessName,
        'tax_id': details.taxId,
        'business_address': details.businessAddress,
      });
      await api.put(
        '${api.host}/api/teams/$teamId/billing-details',
        body: payload,
      );
      return true;
    } on ApiException catch (apiException) {
      final response = apiException.response;
      var message = '[ERROR] setBillingDetails()\n${response.body}';
      log.severe(message);
      return false;
    }
  }

  Future<void> deleteApi(int teamId, String password) async {
    var response = await api.delete(
      '${api.host}/api/teams/$teamId',
      body: jsonEncode(
        {
          'data': {'password': password}
        },
      ),
    );
    if (response.statusCode == 200 || response.statusCode == 302) {
      return true;
    }
    return false;
  }
}
