/// API calls for a user's volumes

import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/data_model.dart';

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

  Future<Iterable<TeamMemberDM>> teamMembers(int teamId) async {
    // Get the user's team volumes
    final res = await api.getFromPath('/api/teams/$teamId/affiliates');
    try {
      final data = json.decode(res.body) as List<dynamic>;
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
}
