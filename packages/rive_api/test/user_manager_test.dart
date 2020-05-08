import 'dart:async';

import 'package:mockito/mockito.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rive_api/src/api/api.dart';
import 'package:rive_api/src/model/model.dart';
import 'package:rive_api/src/manager/manager.dart';
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
      when(riveApi.getFromPath('/api/me'))
          .thenAnswer((_) async => successMeResponse);
      mockedMeApi = MeApi(riveApi);
      userManager = UserManager.tester(mockedMeApi);
    });
    tearDown(() {
      Plumber().reset();
    });

    test('load me', () async {
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

      final checks = [
        (Me me) => me.name == 'MaxMax',
        (Me me) => me == null,
      ];

      Plumber().getStream<Me>().listen((event) {
        var check = checks.removeAt(0);
        if (checks.length == 0) {
          expect(check(event), true);
          testComplete.complete();
        }
      });

      // first logout doesnt change anything
      await userManager.logout();
      await userManager.loadMe();
      await userManager.logout();

      await testComplete.future;
    });

    test('sequence', () async {
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

      await userManager.loadMe();
      await userManager.logout();
      await userManager.loadMe();

      await testComplete.future;
    });
  });
}
