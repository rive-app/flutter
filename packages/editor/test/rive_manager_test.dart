@Timeout(Duration(seconds: 1))

import 'package:mockito/mockito.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/plumber.dart';
import 'package:rive_editor/rive/managers/notification_manager.dart';
import 'package:rive_editor/rive/managers/rive_manager.dart';
import 'package:rive_editor/rive/rive.dart';

import 'helpers/test_helpers.dart';
import 'helpers/test_models.dart';

class MockTeamApi extends Mock implements TeamApi {
  final host = '';
}

class MockNotificationsApi extends Mock implements NotificationsApi {
  final host = '';
}

void main() {
  group('Rive Manager ', () {
    TeamApi mockedTeamApi;
    NotificationsApi mockedNotificationsApi;
    RiveManager riveManager;
    NotificationManager notificationManager;
    setUp(() {
      mockedTeamApi = MockTeamApi();
      mockedNotificationsApi = MockNotificationsApi();
      notificationManager =
          NotificationManager.tester(mockedNotificationsApi, mockedTeamApi);
      riveManager = RiveManager.tester(notificationManager);
    });
    tearDown(() {
      Plumber().reset();
    });

    test('Change directory doesnt trigger empty dir twice', () async {
      final testComplete = testStream(
        Plumber().getStream<CurrentDirectory>(),
        [
          (CurrentDirectory directory) => directory != null,
          (CurrentDirectory directory) => directory == null,
          (CurrentDirectory directory) => directory != null,
          (CurrentDirectory directory) => directory == null,
        ],
      );

      // these events will compress down unpredictably if
      // if we just fire them all in at once.
      Plumber().message(getCurrentDirectory());
      await Future<dynamic>.delayed(const Duration(milliseconds: 10));
      Plumber().message(HomeSection.community);
      await Future<dynamic>.delayed(const Duration(milliseconds: 10));
      Plumber().message(HomeSection.notifications);
      await Future<dynamic>.delayed(const Duration(milliseconds: 10));
      Plumber().message(HomeSection.recents);
      await Future<dynamic>.delayed(const Duration(milliseconds: 10));
      Plumber().message(getCurrentDirectory());
      await Future<dynamic>.delayed(const Duration(milliseconds: 10));
      Plumber().message(HomeSection.recents);

      await testComplete.future;
    });

    test('Change directory selects files on current directory', () async {
      final testComplete = testStream(
        Plumber().getStream<HomeSection>(),
        [
          (HomeSection homeSection) => homeSection == HomeSection.files,
          (HomeSection homeSection) => homeSection == HomeSection.community,
          (HomeSection homeSection) => homeSection == HomeSection.files,
          (HomeSection homeSection) => homeSection == HomeSection.notifications,
        ],
      );

      // these events will compress down unpredictably if
      // if we just fire them all in at once.
      Plumber().message(getCurrentDirectory());
      await Future<dynamic>.delayed(const Duration(milliseconds: 10));

      Plumber().message(HomeSection.community);
      await Future<dynamic>.delayed(const Duration(milliseconds: 10));

      Plumber().message(getCurrentDirectory());
      await Future<dynamic>.delayed(const Duration(milliseconds: 10));

      Plumber().message(getCurrentDirectory(folderId: 2));
      await Future<dynamic>.delayed(const Duration(milliseconds: 10));

      Plumber().message(getCurrentDirectory(folderId: 3));
      await Future<dynamic>.delayed(const Duration(milliseconds: 10));

      Plumber().message(HomeSection.notifications);

      await testComplete.future;
    });
  });
}
