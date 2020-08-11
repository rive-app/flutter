import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/plumber.dart';

import 'fixtures/api_responses.dart';
import 'helpers/test_helpers.dart';

class MockRiveApi extends Mock implements RiveApi {
  final host = '';
}

void main() {
  group('User Manager ', () {
    MockRiveApi riveApi;
    MeApi mockedMeApi;
    UserManager userManager;
    setUp(() {
      riveApi = MockRiveApi();
      when(riveApi.getFromPath('/api/me'))
          .thenAnswer((_) async => successMeResponse);
      mockedMeApi = MeApi(riveApi);
      userManager = UserManager.tester(mockedMeApi);
    });
    tearDown(() {
      Plumber().reset();
    });

    test('load me', () async {
      final testComplete = Completer<void>();

      Plumber().getStream<Me>().listen((event) {
        expect(event.name, 'MaxMax');
        testComplete.complete();
      });

      await userManager.loadMe();

      await testComplete.future;
    });

    test('logout', () async {
      final testComplete = testStream(Plumber().getStream<Me>(), [
        (Me me) => me == null,
        (Me me) => me.name == 'MaxMax',
        (Me me) => me == null,
      ]);

      // Send empty user first.
      userManager.logout();
      await userManager.loadMe();
      userManager.logout();

      await testComplete.future;
    });

    test('sequence', () async {
      final testComplete = testStream(Plumber().getStream<Me>(), [
        (Me me) => me.name == 'MaxMax',
        (Me me) => me == null,
        (Me me) => me.name == 'MaxMax',
      ]);

      await userManager.loadMe();
      userManager.logout();
      await userManager.loadMe();

      await testComplete.future;
    });
  });
}
