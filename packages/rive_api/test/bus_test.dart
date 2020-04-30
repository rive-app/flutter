import 'dart:async';

/// Me tests
import 'dart:convert';
import 'package:mockito/mockito.dart';
import 'package:rive_api/src/bus.dart';

import 'package:test/test.dart';
import 'package:rive_api/src/model/me.dart';
import 'package:rive_api/src/manager/me.dart';
import 'package:rive_api/src/api/me.dart';

class MockMeApi extends Mock implements MeApi {}

void main() {
  Bus bus;
  MockMeApi meApi;

  setUp(() {
    bus = Bus();

    meApi = MockMeApi();
    when(meApi.whoami).thenAnswer(
      (i) => Future.value(
        Me(
            signedIn: true,
            id: 1,
            ownerId: 2,
            name: 'Matt',
            avatarUrl: 'http://example.avatar.com'),
      ),
    );
  });

  group('Bus', () {
    test('Basic user data is routed correctly', () async {
      MeManager(controller: bus.meController, api: meApi);
      final uiMock = bus.meStream;
      final c = Completer();

      uiMock.listen((me) {
        expect(me, isNotNull);
        expect(me.name, 'Matt');
        c.complete();
      });

      await c.future;
    });
  });
}
