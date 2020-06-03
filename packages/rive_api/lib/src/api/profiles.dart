import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/models/owner.dart';
import 'package:rive_api/models/profile.dart';
import 'package:utilities/deserialize.dart';

class ProfilesApi {
  ProfilesApi([RiveApi api]) : api = api ?? RiveApi();
  final RiveApi api;
  final _log = Logger('Rive API');
  RiveProfilesApi(this.api);

  Future<void> updateInfo(Owner owner, {Profile profile}) async {
    if (owner is Team) {
      return _updateTeamInfo(owner, profile);
    } else if (owner is User) {
      return _updateUserInfo(owner, profile);
    }
  }

  // PUT /api/teams/<teamId>
  Future<void> _updateTeamInfo(Team team, Profile profile) async {
    var teamId = team.ownerId;
    String payload = jsonEncode({
      'name': profile.name,
      'username': profile.username,
      'location': profile.location,
      'website': profile.website,
      'blurb': profile.bio,
      'twitter': profile.twitter,
      'instagram': profile.instagram,
      'dribbble': profile.dribbble,
      'linkedin': profile.linkedin,
      'behance': profile.behance,
      'vimeo': profile.vimeo,
      'github': profile.github,
      'medium': profile.medium,
    });

    print("Team: ${team.ownerId} $payload");
    var response =
        await api.put(api.host + '/api/teams/$teamId', body: payload);
    print("OK? ${response.statusCode}");
    if (response.statusCode != 200) {
      // TODO: some form of error handling? also whats wrong with our error
      // logging :D
      var message = 'Could not create new team ${response.body}';
      _log.severe(message);
      print(message);
    }
  }

  Future<void> _updateUserInfo(User team, Profile profile) async {
    // TODO:
    // We could use the current `/register` route,
    // but it needs some fundamental information like email that we currently
    // don't have in this context.
    // Will need a custom route to support that.
  }

  Future<ProfileDM> getInfo(Owner owner) async {
    String url = api.host;
    if (owner is Team) {
      url += '/api/teams/${owner.ownerId}';
    } else {
      url += '/api/profile';
    }
    var response = await api.get(url);
    print("Gotten profile: ${response.body}");
    if (response.statusCode != 200) {
      var message = 'Could not get team info ${response.body}';
      _log.severe(message);
      print(message);
      return null;
    }
    Map<String, dynamic> data;
    try {
      data = json.decodeMap(response.body);
    } on FormatException catch (e) {
      _log.severe('Unable to parse response from server: $e');
    }
    return ProfileDM.fromData(data);
  }
}
