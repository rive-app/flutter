/// API calls for a user's volumes

import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/data_model.dart';
import 'package:rive_api/model.dart';
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
      _log.severe('Error formatting teams api response: $e');
      rethrow;
    }
  }

  Future<Iterable<TeamMemberDM>> teamMembers(int teamId) async {
    // Get the user's team volumes
    final res = await api.getFromPath('/api/teams/$teamId/affiliates');
    try {
      final data = json.decodeList<Map<String, dynamic>>(res.body);
      return TeamMemberDM.formDataList(data);
    } on FormatException catch (e) {
      _log.severe('Error formatting teams api response: $e');
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

  /// GET /api/teams/<team_id>
  /// Returns the teams info.
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
  Future<bool> updateProfile(Team team, Profile profile) async {
    var teamId = team.ownerId;
    var response =
        await api.put(api.host + '/api/teams/$teamId', body: profile.encoded);
    if (response.statusCode != 200) {
      var message = 'Could not create new team ${response.body}';
      log.severe(message);
      return false;
    }
    return true;
  }
}
