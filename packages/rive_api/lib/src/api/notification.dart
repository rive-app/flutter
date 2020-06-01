/// API calls for the logged-in user

import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/data_model.dart';
import 'package:utilities/deserialize.dart';

final Logger log = Logger('Rive API');

/// API for accessing user notifications
class NotificationsApi {
  NotificationsApi([RiveApi api]) : api = api ?? RiveApi();
  final RiveApi api;

  /// GET /api/notifications
  /// Returns the current notifications for a user
  Future<List<NotificationDM>> get notifications async {
    final res = await api.get('${api.host}/api/notifications');

    final data = json.decodeMap(res.body);
    assert(
      data.containsKey('data') && data.containsKey('count'),
      'Incorrect json format for notifications',
    );
    // Need to decode a second time as we have json within json

    dynamic decodedData = data['data'];
    if (decodedData is String) {
      decodedData = json.decode(decodedData as String);
    }

    assert(decodedData is List,
        'at this point decodedData must be a list of js objects');

    // Adding in a test team notification temporarily
    final notifications = <NotificationDM>[]..addAll(
        NotificationDM.fromDataList(
          (decodedData as List).cast<Map<String, dynamic>>(),
        ),
      );
    return notifications;
  }

  /// GET /api/notifications
  /// Returns the current notification count for a user
  Future<int> get notificationCount async {
    var res = await api.get('${api.host}/api/notifications');
    final data = json.decodeMap(res.body);
    assert(
      data.containsKey('data') && data.containsKey('count'),
      'Incorrect json format for notifications',
    );

    return data.getInt('count');
  }
}
