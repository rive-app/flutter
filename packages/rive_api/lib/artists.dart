import 'dart:convert';
import 'dart:core';

import 'package:logging/logging.dart';

import 'api.dart';
import 'user.dart';

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
}
