import 'dart:convert';
import 'dart:core';

import 'api.dart';
import 'user.dart';

class RiveArtists {
  final RiveApi api;
  RiveArtists(this.api);

  Future<List<RiveUser>> list(Iterable<int> ownerIds) async {
    String ids = jsonEncode(ownerIds.toList(growable: false));
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
  }
}
