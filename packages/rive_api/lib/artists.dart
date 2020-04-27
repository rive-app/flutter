import 'dart:convert';
import 'dart:core';

import 'package:logging/logging.dart';

import 'package:rive_api/src/api/api.dart';
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

  /// Get autocomplete results for some value typed into a text field.
  /// [text] provides the input text for this autocomplete search.
  /// [filterIds] is a Set of owner ids that this autocomplete should filter
  /// against. If one of the owner ids is a result to this autcomplete,
  /// then this result won't be added to the list of results.
  /// 
  /// N.B. that this returns results that have some markup for our old web version 
  /// and the id values returned by the backedn are actually userIds. 
  /// We should cleanup this route on stryker/arkham so that it returns 
  /// the avatar too, no markup, and the ownerId instead of userId.
  Future<List<RiveUser>> autocomplete(String text, Set<int> filterIds) async {
    try {
      var response = await api.get(api.host +
          '/api/search/ac/avatar_artists/${Uri.encodeComponent(text)}');

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
            if (user != null && !filterIds.contains(user.ownerId)) {
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
}
