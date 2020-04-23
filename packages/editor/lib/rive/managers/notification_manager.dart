import 'dart:async';

import 'package:rive_api/teams.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/apis/notification.dart';
import 'package:rive_api/models/notification.dart';

import 'package:rxdart/rxdart.dart';
import 'package:meta/meta.dart';

/// State manager for notifications
class NotificationManager {
  NotificationManager({@required RiveApi api})
      : _api = NotificationsApi(api),
        _teamApi = RiveTeamsApi(api) {
    _init();
  }
  final NotificationsApi _api;
  final RiveTeamsApi _teamApi;

  /*
   * Outbound streams
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

  /// Outbound stream of any notification messaging errors
  final _notificationErrorController = BehaviorSubject<HttpException>();
  Stream<HttpException> get notificationErrorStream =>
      _notificationErrorController.stream;

  /*
   * Inbound sinks
   */

  /// Inbound acceptance of a team invite
  final _acceptTeamInviteController =
      StreamController<RiveTeamInviteNotification>.broadcast();
  Sink<RiveTeamInviteNotification> get acceptTeamInvite =>
      _acceptTeamInviteController;

  /// Inbound decline of a team invite
  final _declineTeamInviteController =
      StreamController<RiveTeamInviteNotification>.broadcast();
  Sink<RiveTeamInviteNotification> get declineTeamInvite =>
      _acceptTeamInviteController;

  /// Clean up all the stream controllers and that polling timer
  void dispose() {
    _notificationsController.close();
    _notificationCountController.close();
    _notificationErrorController.close();
    _acceptTeamInviteController.close();
    _declineTeamInviteController.close();
    _poller?.cancel();
  }

  /*
   * State
   */

  /// Initiatize the state
  void _init() {
    // Handle incoming team invitation acceptances
    _acceptTeamInviteController.stream.listen(_acceptTeamInvite);
    // Handle incloing team invitation declines
    _declineTeamInviteController.stream.listen(_declineTeamInvite);
    // Fetch the notifications
    _fetchNotifications();
    // Start the polling timer to periodically pull notifications
    _poller = Timer.periodic(
      const Duration(seconds: 60),
      (t) => _fetchNotifications(),
    );
  }

  /// Cache the notifications coming from the server
  final __notifications = <RiveNotification>[];
  List<RiveNotification> get _notifications => __notifications;
  set _notifications(List<RiveNotification> values) {
    __notifications.clear();
    __notifications.addAll(values);
    _notificationsController.add(__notifications);
    _notificationCountController.add(__notifications.length);
  }

  /// Removes a notification from the list
  void _removeNotification(RiveNotification n) {
    _notifications.remove(n);
    _notificationsController.add(__notifications);
    _notificationCountController.add(__notifications.length);
  }

  HttpException __notificationError;
  HttpException get _notificationError => __notificationError;
  set _notificationError(HttpException exception) {
    if (_notificationError != exception) {
      __notificationError = exception;
      _notificationErrorController.add(__notificationError);
    }
  }

  /// Timer for polling new notifications
  Timer _poller;

  /*
   * API calls
   */

  /// Fetch a user's notifications from the back end
  Future<void> _fetchNotifications() async {
    try {
      _notifications = await _api.notifications;
      _notificationError = null;
    } on HttpException catch (e) {
      _notificationError = e;
      print('Failed to update notifications $e');
    }
  }

  /// Accepts a team invite
  Future<void> _acceptTeamInvite(RiveTeamInviteNotification n) async {
    await _teamApi.acceptInvite(n.teamId);
    _removeNotification(n);
  }

  /// Decline a team invite
  Future<void> _declineTeamInvite(RiveTeamInviteNotification n) async {
    await _teamApi.declineInvite(n.teamId);
    _removeNotification(n);
  }
}
