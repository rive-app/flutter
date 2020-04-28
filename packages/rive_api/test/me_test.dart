import 'dart:async';

/// Model tests
import 'dart:convert';
import 'package:mockito/mockito.dart';

import 'package:test/test.dart';
import 'package:rive_api/src/model/me.dart';
import 'package:rive_api/src/manager/me.dart';
import 'package:rive_api/src/api/me.dart';

void main() {
  group('Model', () {
    test('Me models are constructed correctly', () {
      final me = Me(name: 'Matt', avatarUrl: 'http://example.avatar.com');

      expect(me.name, 'Matt');
      expect(me.avatarUrl, 'http://example.avatar.com');
    });

    test('Me models are contructed correctly from json', () {
      final jsonMe =
          json.encode({'name': 'Matt', 'avatar': 'http://example.avatar.com'});
      final me = Me.fromData(json.decode(jsonMe));

      expect(me.name, 'Matt');
      expect(me.avatarUrl, 'http://example.avatar.com');
    });
  });

  group('Manager', () {
    test('Me manager provides logged in user data', () async {
      // Mock out the api
      final mockApi = MockMeApi();
      when(mockApi.whoami()).thenAnswer(
        (i) => Future.value(
          Me(name: 'Matt', avatarUrl: 'http://example.avatar.com'),
        ),
      );

      // Track async completion of the test
      final testComplete = Completer();

      final manager = MeManager(mockApi);
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

/*
 * Mocks
 */

class MockMeApi extends Mock implements MeApi {}
