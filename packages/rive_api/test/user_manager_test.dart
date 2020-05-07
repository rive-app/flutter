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
    tearDown(() {
      Plumber().reset();
    });

    test('load me', () async {
      final riveApi = MockRiveApi();
      when(riveApi.getFromPath('/api/me'))
          .thenAnswer((_) async => successMeResponse);

      final mockedMeApi = MeApi(riveApi);
      final userManager = UserManager();
      userManager.meApi = mockedMeApi;

      final testComplete = Completer();

      Plumber().getStream<Me>().listen((event) {
        expect(event.name, 'MaxMax');
        testComplete.complete();
      });

      userManager.loadMe();

      await testComplete.future;
    });

    test('logout', () async {
      final userManager = UserManager();

      final testComplete = Completer();

      Plumber().getStream<Me>().listen((event) {
        expect(event, null);
        testComplete.complete();
      });

      userManager.logout();

      await testComplete.future;
    });
  });
}
