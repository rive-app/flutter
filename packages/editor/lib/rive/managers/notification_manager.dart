import 'dart:async' show Timer;

import 'package:rxdart/rxdart.dart';
import 'package:meta/meta.dart';

import 'package:rive_api/api.dart';
import 'package:rive_api/apis/notification.dart';
import 'package:rive_api/models/notification.dart';

/// State manager for notifications
class NotificationManager {
  NotificationManager({@required RiveApi api}) : _api = NotificationsApi(api) {
    _fetchNotifications();
    // Start the polling timer to periodically pull notifications
    _poller = Timer.periodic(
      const Duration(seconds: 60),
      (t) => _fetchNotifications(),
    );
  }
  final NotificationsApi _api;

  /*
   * Streams
   */

  /// Outbound stream of an interable of notifications
  final _notificationsController =
      BehaviorSubject<Iterable<RiveNotification>>();
  Stream<Iterable<RiveNotification>> get notificationsStream =>
      _notificationsController.stream;

  /// Outbound stream of the notifications count
  final _notificationCountController = BehaviorSubject<int>();
  Stream<int> get notificationCountStream =>
      _notificationCountController.stream;

  /// Clean up all the stream controllers and that polling timer
  void dispose() {
    _notificationsController.close();
    _notificationCountController.close();
    _poller?.cancel();
  }

  /*
   * State
   */

  /// Cache the notifications coming from the server
  final __notifications = <RiveNotification>[];
  // List<RiveNotification> get _notifications => __notifications;
  set _notifications(List<RiveNotification> values) {
    __notifications.clear();
    __notifications.addAll(values);
    _notificationsController.add(__notifications);
    _notificationCountController.add(__notifications.length);
  }

  /// Timer for polling new notifications
  Timer _poller;

  /*
   * API calls
   */

  Future<void> _fetchNotifications() async =>
      _notifications = await _api.notifications;
}
