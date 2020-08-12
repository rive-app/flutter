import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/plumber.dart';
import 'package:rive_editor/rive/managers/notification_manager.dart';
import 'package:rive_editor/rive/rive.dart';

/// General manager for general ui things
class RiveManager with Subscriptions {
  static final RiveManager _instance = RiveManager._();
  factory RiveManager() => _instance;

  Rive rive;

  NotificationManager _notificationsManager;

  RiveManager._() {
    _notificationsManager = NotificationManager();
    _attach();
  }

  RiveManager.tester(NotificationManager notificationManager) {
    _notificationsManager = notificationManager;
    _attach();
  }

  void _attach() {
    subscribe<HomeSection>(_newHomeSection);
    subscribe<CurrentDirectory>(_newCurrentDirectory);
    subscribe<File>(_fileUpdates);
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
      _notificationsManager.markNotificationsRead();
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
    final teams = Plumber().peek<List<Team>>();
    final targetTeam =
        teams.firstWhere((element) => element.ownerId == teamOwnerId);
    // 1 is the magic base folder
    FileManager().loadBaseFolder(targetTeam);
  }

  void _fileUpdates(File file) {
    Plumber().message<File>(file, file.hashCode);
    var openFileTab = rive.fileTabs.firstWhere(
        (tab) =>
            tab.file != null &&
            tab.file.ownerId == file.fileOwnerId &&
            tab.file.fileId == file.id,
        orElse: () => null);
    if (openFileTab == null) {
      return;
    }
    openFileTab.file.updateName(file.name);
  }
}
