import 'dart:async';

import 'package:rive_api/api.dart';
import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/plumber.dart';
import 'package:rive_editor/platform/file_save.dart';
import 'package:rive_editor/rive/managers/notification_manager.dart';
import 'package:rive_editor/rive/managers/task_manager.dart';
import 'package:rive_editor/rive/rive.dart';

class FileCounter {
  final StreamSubscription stream;
  int hits;

  FileCounter(this.stream, {this.hits = 0});
}

/// General manager for general ui things
class RiveManager with Subscriptions {
  static final RiveManager _instance = RiveManager._();
  factory RiveManager() => _instance;

  Rive rive;
  final subs = <int, FileCounter>{};

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
    subscribe<File>(_checkForUpdates);
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

  void _checkForUpdates(File file) {
    // File is getting updated.
    // lets make sure we watch out for further changes
    // as the backend may make amendments
    Plumber().message(file, file.hashCode);
    subs[file.hashCode] = FileCounter(
      subscribe<File>(_updateEditor, file.hashCode),
    );
  }

  void _updateEditor(File file) {
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
    subs[file.hashCode].hits += 1;
    if (subs[file.hashCode].hits > 1) {
      removeSubscription(subs[file.hashCode].stream);
      subs.remove(file.hashCode);
    }
  }

  Future<void> export() async {
    var selection = Plumber().peek<Selection>();

    if (selection == null || selection.isEmpty) {
      Plumber().message(GlobalMessage(
          'Please select files or folders to export',
          'dismiss',
          () => Plumber().flush<GlobalMessage>()));
      return;
    }

    var payload = <String, Map<String, List<int>>>{};
    selection.files.forEach((file) {
      // TODO: untangle me
      final actualFile = Plumber().peek<File>(file.hashCode);
      payload[actualFile.fileOwnerId.toString()] ??= {
        'files': [],
        'folders': []
      };
      payload[actualFile.fileOwnerId.toString()]['files'].add(actualFile.id);
    });
    selection.folders.forEach((folder) {
      payload[folder.ownerId.toString()] ??= {'files': [], 'folders': []};
      payload[folder.ownerId.toString()]['folders'].add(folder.id);
    });

    selection.files.map((e) => e.id).toList();

    Plumber().message(GlobalMessage(
        'Exporting selected files, this can take a minute.',
        'dismiss',
        () => Plumber().flush<GlobalMessage>()));
    final task = await TasksApi().exportRiveFiles(payload);

    // TODO: handle timeout?
    TaskManager().notifyTasks({task.taskId}, (TaskCompleted result) async {
      var zipBytes = await TasksApi().taskData(result.taskId);
      if (await FileSave.save('export.zip', zipBytes)) {
        Plumber().message(
          GlobalMessage('Export completed.', 'dismiss',
              () => Plumber().flush<GlobalMessage>()),
        );
      } else {
        Plumber().message(
          GlobalMessage('Export cancelled.', 'dismiss',
              () => Plumber().flush<GlobalMessage>()),
        );
      }
    });
  }
}
