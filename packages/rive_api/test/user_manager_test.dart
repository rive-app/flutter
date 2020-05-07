import 'dart:async';

import 'package:mockito/mockito.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rive_api/src/api/api.dart';
import 'package:rive_api/src/model/model.dart';
import 'package:rive_api/src/manager/user.dart';
import 'package:rive_api/src/plumber.dart';

import 'fixtures/api_responses.dart';

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
      mockedMeApi = MeApi(riveApi);
      userManager = UserManager();
      userManager.meApi = mockedMeApi;

      Plumber().reset();
    });
    tearDown(() {
      Plumber().reset();
    });

    test('load me', () async {
      when(riveApi.getFromPath('/api/me'))
          .thenAnswer((_) async => successMeResponse);

      final testComplete = Completer();

      Plumber().getStream<Me>().listen((event) {
        expect(event.name, 'MaxMax');
        testComplete.complete();
      });

      userManager.loadMe();

      await testComplete.future;
    });

    test('logout', () async {
      final testComplete = Completer();

      Plumber().getStream<Me>().listen((event) {
        expect(event, null);
        testComplete.complete();
      });

      userManager.logout();

      await testComplete.future;
    });

    test('sequence', () async {
      final userManager = UserManager();
      when(riveApi.getFromPath('/api/me'))
          .thenAnswer((_) async => successMeResponse);

      final testComplete = Completer();

      final checks = [
        (Me me) => me.name == 'MaxMax',
        (Me me) => me == null,
        (Me me) => me.name == 'MaxMax',
      ];

      Plumber().getStream<Me>().listen((event) {
        var check = checks.removeAt(0);
        if (checks.length == 0) {
          expect(check(event), true);
          testComplete.complete();
        }
      });

      userManager.loadMe();
      userManager.logout();
      userManager.loadMe();

      await testComplete.future;
    });
  });
}
