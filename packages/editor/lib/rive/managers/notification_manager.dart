import 'dart:async';
import 'package:pedantic/pedantic.dart';

import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart' as model;
import 'package:rive_api/model.dart';
import 'package:rive_api/plumber.dart';
import 'package:rive_api/rive_api.dart';
import 'package:rive_api/api.dart';

const pollDuration = Duration(minutes: 2);

/// State manager for notifications
class NotificationManager with Subscriptions {
  static final NotificationManager _instance = NotificationManager._();
  factory NotificationManager() => _instance;

  NotificationManager._() {
    _notificationsApi = NotificationsApi();
    _teamApi = TeamApi();
    _attach();
  }

  NotificationManager.tester(
    NotificationsApi notificationsApi,
    TeamApi teamApi,
  ) {
    _notificationsApi = notificationsApi;
    _teamApi = teamApi;
    _attach();
  }

  NotificationsApi _notificationsApi;
  TeamApi _teamApi;

  /// Clean up all the stream controllers and that polling timer
  void dispose() {
    super.dispose();
    _poller?.cancel();
  }

  /// Initiatize the state
  void _attach() {
    _fetchNotifications();
    Plumber().getStream<Me>().listen((event) {
      _fetchNotifications();
    });
    _poller = Timer.periodic(
      pollDuration,
      (t) => _fetchNotifications(),
    );
  }

  /// Timer for polling new notifications
  Timer _poller;

  /*
   * API calls
   */

  /// Fetch a user's notifications from the back end
  Future<void> _fetchNotifications() async {
    if (Plumber().peek<Me>() == null) {
      return;
    }
    try {
      var notifications =
          model.Notification.fromDMList(await _notificationsApi.notifications);
      Plumber().message(notifications);
      print('fired of some notifications');
      // _notificationError = null;
    } on HttpException catch (e) {
      print('Failed to update notifications $e');
    }
  }

  /// Accepts a team invite
  Future<void> acceptTeamInvite(model.TeamInviteNotification n) async {
    await _teamApi.acceptInvite(n.teamId);
    unawaited(_fetchNotifications());
    TeamManager().loadTeams();
  }

  /// Decline a team invite
  Future<void> declineTeamInvite(model.TeamInviteNotification n) async {
    await _teamApi.declineInvite(n.teamId);
    unawaited(_fetchNotifications());
  }
}
