import 'dart:async';

/// Me tests
import 'dart:convert';
import 'package:mockito/mockito.dart';

import 'package:test/test.dart';
import 'package:rive_api/src/model/me.dart';
import 'package:rive_api/src/manager/me.dart';
import 'package:rive_api/src/api/me.dart';

class MockMeApi extends Mock implements MeApi {}

void main() {
  Me testMe;

  setUp(() {
    testMe = Me.testData();
  });

  group('Model', () {
    test('Me models are constructed correctly', () {
      expect(testMe.signedIn, isTrue);
      expect(testMe.id, 40877);
      expect(testMe.ownerId, 40955);
      expect(testMe.name, 'Matt');
      expect(testMe.username, 'matt');
      expect(testMe.avatarUrl, 'http://example.avatar.com');
      expect(testMe.isAdmin, isFalse);
      expect(testMe.isPaid, isFalse);
      expect(testMe.notificationCount, 0);
      expect(testMe.verified, isFalse);
      expect(testMe.notice, 'confirm-email');
    });

    test('Me models are contructed correctly from json', () {
      final jsonMe = json.encode({
        'signedIn': true,
        'id': 1,
        'ownerId': 2,
        'name': 'Matt',
        'avatar': 'http://example.avatar.com'
      });
      final me = Me.fromData(json.decode(jsonMe));

      expect(me.signedIn, isTrue);
      expect(me.id, 1);
      expect(me.ownerId, 2);
      expect(me.name, 'Matt');
      expect(me.avatarUrl, 'http://example.avatar.com');
    });
  });

  group('Manager', () {
    test('Me manager provides logged in user data', () async {
      // Mock out the api
      final mockApi = MockMeApi();
      when(mockApi.whoami).thenAnswer(
        (i) => Future.value(testMe),
      );

      // Track async completion of the test
      final testComplete = Completer();

      final manager = MeManager(api: mockApi);
      manager.me.listen((me) {
        expect(me.name, 'Matt');
        expect(me.avatarUrl, 'http://example.avatar.com');
        // Mark the test as completed
        testComplete.complete();
      });

      // Wait for the test to complete
      await testComplete.future;

      manager.dispose();
    });
  });
}
