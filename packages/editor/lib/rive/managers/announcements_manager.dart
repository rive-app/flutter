import 'dart:async';

import 'package:rive_api/api.dart';
import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart' as model;
import 'package:rive_api/plumber.dart';
import 'package:rive_api/rive_api.dart';
import 'package:rive_editor/rive/rive.dart';

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
    _fetchAnnouncements();

    /// When the logged in user is changed, fetch announcements for the new user
    subscribe<model.Me>((_) => _fetchAnnouncements());
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
    final me = Plumber().peek<model.Me>();
    if (me == null || me.isEmpty) {
      return;
    }
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
    await _announcementsApi.markAnnouncementsRead();
    await _fetchAnnouncements();
  }

  Future<void> update() async {
    // if we update and are already on the home section
    // we may as well mark the notificatinos as read, as we've just read them.
    if (Plumber().peek<HomeSection>() == HomeSection.notifications) {
      await markAnnouncementsRead();
    } else {
      await _fetchAnnouncements();
    }
  }
}
