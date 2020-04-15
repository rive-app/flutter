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

  /// GET /api/notifications (NOT IMPLEMENTED YET)
  /// Returns the current notifications for a user
  // Future<List<Notification>> _notifications() async {
  //   var response = await api.get(api.host + '/api/notifications');
  //   List<dynamic> data = json.decode(response.body);

  //   final notifications = Notification.fromDataList(data);
  //   return notifications;
  // }

  static final tmpData = [
    {
      'type': 'follow',
      'ownerId': 1,
      'senderId': '2',
      'senderName': 'Matt Sullivan',
      'date': 1586832870
    },
    {
      'type': 'follow',
      'ownerId': 1,
      'senderId': '3',
      'senderName': 'Luigi Rosso',
      'date': 1586823871
    },
    {
      'type': 'team_invite',
      'ownerId': 1,
      'senderId': 2,
      'senderName': 'Matt Sullivan',
      'teamId': 1,
      'teamName': 'Rive',
      'inviteId': 1,
      'date': 1586818871,
    },
    {
      'type': 'follow',
      'ownerId': 1,
      'senderId': '4',
      'senderName': 'Umberto Sonnino',
      'date': 1586812872
    },
    {
      'type': 'follow',
      'ownerId': 1,
      'senderId': '3',
      'senderName': 'Max Talbot',
      'date': 1586632873,
    },
  ];

  Future<List<RiveNotification>> get notifications {
    final notifications = RiveNotification.fromDataList(tmpData);
    return Future.value(notifications);
    // return notifications;
  }
}
