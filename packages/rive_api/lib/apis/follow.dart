import 'dart:convert';
import 'dart:core';

import 'package:logging/logging.dart';
import 'package:rive_api/src/api/api.dart';
import 'package:rive_api/models/follow.dart';

final Logger log = Logger('Rive API');

/// API for accessing user notifications
class FollowingApi {
  const FollowingApi(this.api);
  final RiveApi api;

  /// List of users that this user is following
  /// GET: /api/artists/:owner_id/followers-recent/:page_id?
  /// TODO: this is wired into recent followers, fix
  Future<Iterable<RiveFollowee>> followees(int ownerId) async {
    final res =
        await api.get('${api.host}/api/artists/$ownerId/following-oldest');
    if (res.statusCode == 200) {
      final followees =
          RiveFollowee.fromDataList(json.decode(res.body)['artists']);
      return followees;
    } else {
      throw Exception('Error fetching followees: ${res.statusCode}');
    }
  }

  /// Follow another user
  /// POST: /api/artists/<ownerId>/follow
  Future<void> follow(int ownerId) async {
    final res = await api.post('${api.host}/api/artists/$ownerId/follow');
  }

  /// Unfollow another user
  /// POST: /api/artists/<ownerId>/unfollow
  Future<void> unfollow(int ownerId) async {
    final res = await api.post('${api.host}/api/artists/$ownerId/unfollow');
  }
}
