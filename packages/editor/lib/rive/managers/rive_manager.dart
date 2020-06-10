import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/plumber.dart';
import 'package:rive_editor/rive/managers/notification_manager.dart';
import 'package:rive_editor/rive/rive.dart';

/// General manager for general ui things
class RiveManager with Subscriptions {
  static final RiveManager _instance = RiveManager._();
  factory RiveManager() => _instance;

  RiveManager._() {
    _attach();
  }

  RiveManager.tester() {
    _attach();
  }

  void _attach() {
    subscribe<HomeSection>(_newHomeSection);
    subscribe<CurrentDirectory>(_newCurrentDirectory);
  }

  /// Initiatize the state
  void _newHomeSection(HomeSection newHomeSection) {
    // Handle incoming team invitation acceptances
    if (newHomeSection != HomeSection.files) {
      Plumber().flush<CurrentDirectory>();
    }
    // Handle marking notifications as read when
    // the user opens the notifications panel
    if (newHomeSection == HomeSection.notifications &&
        Plumber().peek<NotificationCount>()?.count != 0) {
      NotificationManager().markNotificationsRead();
    }
    // Handle marking first run when
    // the user opens the getting started panel
    if (newHomeSection == HomeSection.getStarted &&
        (Plumber().peek<Me>()?.isFirstRun ?? false)) {
      UserManager().markFirstRun();
    }
  }

  void _newCurrentDirectory(CurrentDirectory currentDirectory) {
    // Handle incoming team invitation acceptances
    if (currentDirectory != null) {
      if (Plumber().peek<HomeSection>() != HomeSection.files) {
        Plumber().message<HomeSection>(HomeSection.files);
      }
    }
  }

  void viewTeam(int teamOwnerId) {
    // NOTE: you hit this, without having loaded the team
    // this will obviously fail.
    final _plumber = Plumber();
    final teams = Plumber().peek<List<Team>>();
    final targetTeam =
        teams.firstWhere((element) => element.ownerId == teamOwnerId);
    // 1 is the magic base folder
    _plumber.message(CurrentDirectory(targetTeam, 1));
  }
}
