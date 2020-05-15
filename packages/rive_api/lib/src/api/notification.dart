/// API calls for the logged-in user

import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/data_model.dart';

final Logger log = Logger('Rive API');

/// API for accessing user notifications
class NotificationsApi {
  NotificationsApi([RiveApi api]) : api = api ?? RiveApi();
  final RiveApi api;

  /// GET /api/notifications
  /// Returns the current notifications for a user
  Future<List<NotificationDM>> get notifications async {
    final res = await api.get('${api.host}/api/notifications');

    final data = json.decode(res.body);
    assert(
      data.containsKey('data') && data.containsKey('count'),
      'Incorrect json format for notifications',
    );
    // Need to decode a second time as we have json within json

    var decodedData = data['data'];
    if (decodedData is String) {
      decodedData = json.decode(decodedData);
    }

    // Adding in a test team notification temporarily
    final notifications = <NotificationDM>[]
      ..addAll(NotificationDM.fromDataList(decodedData));
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
