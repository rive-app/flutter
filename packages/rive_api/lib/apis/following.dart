import 'dart:core';

import 'package:logging/logging.dart';
import 'package:rive_api/api.dart';

final Logger log = Logger('Rive API');

/// API for accessing user notifications
class FollowingApi {
  const FollowingApi(this.api);
  final RiveApi api;

  /// Follow another user
  /// POST: /api/artists/<ownerId>/follow
  Future<void> follow(int ownerId) async {
    print('Request to follow $ownerId');
    final res = await api.post('${api.host}/api/artists/$ownerId/follow');
    print('Status code: ${res.statusCode}');
  }
}
