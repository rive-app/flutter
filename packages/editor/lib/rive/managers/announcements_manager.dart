import 'dart:async';

import 'package:rive_api/api.dart';
import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart' as model;
import 'package:rive_api/plumber.dart';
import 'package:rive_api/rive_api.dart';

// we really dont need to do this much. this only really is useful if we
// lost our websocket comms right when we got a notification
const pollInterval = Duration(minutes: 30);

/// State manager for announcements
class AnnouncementsManager with Subscriptions {
  static final _instance = AnnouncementsManager._();
  factory AnnouncementsManager() => _instance;

  AnnouncementsManager._() {
    _announcementsApi = AnnouncementsApi();
    _attach();
    _poll();
  }

  AnnouncementsManager.tester(
    AnnouncementsApi announcementsApi,
  ) {
    _announcementsApi = announcementsApi;
    _attach();
  }

  AnnouncementsApi _announcementsApi;

  /// Clean up all the stream controllers and that polling timer
  @override
  void dispose() {
    super.dispose();
    _poller?.cancel();
  }

  /// Initiatize the state
  void _attach() {
    // I don't think we actually need this, subscribe to Me below will
    // immediately call if there's a Me ready (since Plumber uses
    // BehaviorSubjects)
    //_fetchAnnouncements();

    /// When the logged in user is changed, fetch announcements for the new user
    subscribe<model.Me>((me) {
      if (me == null || !me.signedIn) {
        return;
      }
      _fetchAnnouncements();
    });
  }

  void _poll() {
    _poller = Timer.periodic(
      pollInterval,
      (t) => _fetchAnnouncements(),
    );
  }

  /// Timer for polling new announcements
  Timer _poller;

  /*
   * API calls
   */

  /// Fetch a user's announcements from the back end
  /// Also fetches the current new announcements count
  Future<void> _fetchAnnouncements() async {
    try {
      // Fetch announcements
      final announcements =
          model.Announcement.fromDMList(await _announcementsApi.announcements);
      Plumber().message(announcements);
    } on HttpException catch (e) {
      print('Failed to update announcements $e');
    }
  }

  /// Mark all announcements as read
  Future<void> markAnnouncementsRead() async {
    try {
      // Fetch announcements
      final announcements = model.Announcement.fromDMList(
          await _announcementsApi.readAnnoucements);
      Plumber().message(announcements);
    } on HttpException catch (e) {
      print('Failed to update announcements $e');
    }
  }

  bool isAnnouncementNew(model.Announcement announcement) {
    var me = Plumber().peek<model.Me>();
    if (me == null || me.lastAnnoucementRead == null) {
      return true;
    }
    return announcement.validFrom.isAfter(me.lastAnnoucementRead);
  }

  bool anyAnnouncementNew(List<model.Announcement> announcements) {
    var me = Plumber().peek<model.Me>();
    if (announcements == null) {
      return false;
    }
    if (me == null || me.lastAnnoucementRead == null) {
      return announcements.isNotEmpty;
    }
    return announcements.any((announcement) =>
        announcement.validFrom.isAfter(me.lastAnnoucementRead));
  }
}
