import 'dart:async';

import 'package:mockito/mockito.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rive_api/src/api/api.dart';
import 'package:rive_api/src/model/model.dart';

import 'package:rive_api/src/plumber.dart';
import 'package:rive_editor/rive/managers/notification_manager.dart';

import 'helpers/test_models.dart';

class MockTeamApi extends Mock implements TeamApi {
  final host = '';
}

class MockNotificationsApi extends Mock implements NotificationsApi {
  final host = '';
}

void main() {
  group('Notification Manager ', () {
    TeamApi mockedTeamApi;
    NotificationsApi mockedNotificationsApi;
    NotificationManager notificationManager;
    setUp(() {
      mockedTeamApi = MockTeamApi();
      mockedNotificationsApi = MockNotificationsApi();
      when(mockedNotificationsApi.notifications)
          .thenAnswer((_) async => getTestNotifications());
      notificationManager =
          NotificationManager.tester(mockedNotificationsApi, mockedTeamApi);
    });
    tearDown(() {
      Plumber().reset();
    });

    test('load notifications on new me', () async {
      final testComplete = Completer<dynamic>();

      Plumber().getStream<List<Notification>>().listen((notifications) {
        expect(notifications.length, 6);
        expect(notifications.map((n) => n.runtimeType).toSet().length, 6);
        testComplete.complete();
      });

      Plumber().message(getMe());

      await testComplete.future;
    });
  });
}
