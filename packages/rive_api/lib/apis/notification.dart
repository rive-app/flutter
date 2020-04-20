import 'dart:convert';
import 'dart:core';

import 'package:logging/logging.dart';

import 'package:rive_api/api.dart';
import 'package:rive_api/models/notification.dart';

final Logger log = Logger('Rive API');

/// API for accessing user notifications
class NotificationsApi {
  const NotificationsApi(this.api);
  final RiveApi api;

  /// GET /api/notifications
  /// Returns the current notifications for a user
  Future<List<RiveNotification>> get notifications async {
    final res = await api.get('${api.host}/api/notifications');

    final data = json.decode(res.body);
    assert(
      data.containsKey('data') && data.containsKey('count'),
      'Incorrect json format for notifications',
    );
    // Need to decode a second time as we have json within json
    final decodedData = json.decode(data['data']);
    // Adding in a test team notification temporarily
    // TODO: REMOVE
    final notifications = <RiveNotification>[]
      ..addAll(RiveNotification.fromDataList(decodedData))
      ..add(RiveTeamInviteNotification(
        dateTime:
            DateTime.fromMillisecondsSinceEpoch((1587419781 - 10000) * 1000),
        senderId: 40842,
        senderName: 'Matt',
        teamId: 40847,
        teamName: 'Awesome',
        inviteId: 1,
        permission: 15,
      ));
    return notifications;
  }

  /// GET /api/notifications
  /// Returns the current notification count for a user
  Future<int> get notificationCount async {
    var res = await api.get('${api.host}/api/notifications');
    final data = json.decode(res.body);
    assert(
      data.containsKey('data') && data.containsKey('count'),
      'Incorrect json format for notifications',
    );

    return data.getInt('count');
  }
}
