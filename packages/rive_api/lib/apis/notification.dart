import 'dart:convert';
import 'dart:core';

import 'package:logging/logging.dart';

import 'package:rive_api/api.dart';
import 'package:rive_api/models/notification.dart';

/// API for accessing user notifications
class NotificationsApi {
  NotificationsApi(this.api);
  final RiveApi api;
  final Logger log = Logger('Rive API');

  /// GET /api/notifications (NOT IMPLEMENTED YET)
  /// Returns the current notifications for a user
  Future<List<Notification>> get _notifications async {
    var response = await api.get(api.host + '/api/notifications');
    List<dynamic> data = json.decode(response.body);

    final notifications = Notification.fromDataList(data);
    return notifications;
  }

  static final tmpData = [
    {'ownerId': 1, 'senderId': '2', 'name': 'Matt', 'date': '1586832870'},
    {'ownerId': 1, 'senderId': '3', 'name': 'Luigi', 'date': '15868328701'},
    {'ownerId': 1, 'senderId': '4', 'name': 'Umberto', 'date': '15868328702'},
    {'ownerId': 1, 'senderId': '3', 'name': 'Max', 'date': '15868328703'},
  ];

  Future<List<Notification>> get notifications async {
    final notifications = Notification.fromDataList(tmpData);
    return notifications;
  }
}
