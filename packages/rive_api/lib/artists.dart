import 'dart:convert';
import 'dart:core';

import 'package:logging/logging.dart';

import 'package:rive_api/api.dart';
import 'package:rive_api/models/user.dart';

final log = Logger('Rive API');

class RiveArtists {
  final RiveApi api;
  RiveArtists(this.api) : assert(api != null);

  Future<List<RiveUser>> list(Iterable<int> ownerIds) async {
    String ids = jsonEncode(ownerIds.toList(growable: false));
    try {
      var response = await api.post(api.host + '/api/artist/list', body: ids);

      if (response.statusCode == 200) {
        List data;
        try {
          data = json.decode(response.body) as List;
        } on FormatException catch (_) {
          return null;
        }
        List<RiveUser> results = [];
        if (data != null) {
          for (final dynamic value in data) {
            if (value == null || value is! Map<String, dynamic>) {
              continue;
            }

            var user = RiveUser.fromData(value as Map<String, dynamic>,
                requireSignin: false);
            if (user != null) {
              results.add(user);
            }
          }
        }
        return results;
      }
      return null;
    } on Exception catch (e) {
      log.severe('Error communicating with artists endpoint: $e');
      return null;
    }
  }

  /// Get autocomplete results for some value typed into a text field. N.B. that
  /// this returns results that have some markup for our old web version and the
  /// id values returned by the backedn are actually userIds. We should cleanup
  /// this route on stryker/arkham so that it returns the avatar too, no markup,
  /// and the ownerId instead of userId.
  Future<List<RiveUser>> autocomplete(String text) async {
    try {
      var response = await api.get(
          api.host + '/api/search/ac/avatar_artists/${Uri.encodeComponent(text)}');

      if (response.statusCode == 200) {
        List data;
        try {
          data = json.decode(response.body) as List;
        } on FormatException catch (_) {
          return null;
        }
        List<RiveUser> results = [];
        if (data != null) {
          for (final dynamic value in data) {
            if (value == null || value is! Map<String, dynamic>) {
              continue;
            }

            var user =
                RiveUser.fromAutoCompleteData(value as Map<String, dynamic>);
            if (user != null) {
              results.add(user);
            }
          }
        }
        return results;
      }
      return null;
    } on Exception catch (e) {
      log.severe('Error communicating with artists endpoint: $e');
      return null;
    }
  }

  Future<List<int>> sendInvites(
      int teamId, List<int> inviteIds, String permission) async {
    var response = <int>[];
    for (final ownerId in inviteIds) {
      int id = await sendInvite(teamId, ownerId, permission);
      if (id != null) {
        response.add(id);
      }
    }
    return response;
  }

  // POST /api/teams/:team_owner_id/invite
  Future<int> sendInvite(int teamId, int ownerId, String permission) async {
    String payload = jsonEncode({
      "data": {
        "ownerId": ownerId,
        "permission": permission.toLowerCase(),
      }
    });
    var response =
        await api.post(api.host + '/api/teams/$teamId/invite', body: payload);
    if (response.statusCode != 200) {
      var message =
          'Could not invite user $ownerId to team $teamId because:\n${response.body}';
      log.severe(message);
      print(message);
      return null;
    }
    return ownerId;
  }
}
