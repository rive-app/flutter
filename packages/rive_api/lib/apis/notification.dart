import 'dart:convert';
import 'dart:core';

import 'package:logging/logging.dart';

import 'package:rive_api/api.dart';
import 'package:rive_api/models/notification.dart';
import 'package:rive_api/src/deserialize_helper.dart';

final Logger log = Logger('Rive API');

/// API for accessing user notifications
class NotificationsApi {
  const NotificationsApi(this.api);
  final RiveApi api;

  /// GET /api/notifications
  /// Returns the current notifications for a user
  Future<List<RiveNotification>> get notifications async {
    var res = await api.get('${api.host}/api/notifications');

    final data = json.decode(res.body) as Map<String, dynamic>;
    assert(
      data.containsKey('data') && data.containsKey('count'),
      'Incorrect json format for notifications',
    );

    return RiveNotification.fromDataList(data['data']);
  }

  /// GET /api/notifications
  /// Returns the current notification count for a user
  Future<int> get notificationCount async {
    var res = await api.get('${api.host}/api/notifications');

    final data = json.decode(res.body) as Map<String, dynamic>;
    assert(
      data.containsKey('data') && data.containsKey('count'),
      'Incorrect json format for notifications',
    );

    return data.getInt('count');
  }
}
