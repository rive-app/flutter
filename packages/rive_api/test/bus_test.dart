import 'dart:async';
import 'package:test/test.dart';

import 'package:mockito/mockito.dart';
import 'package:rive_api/src/bus.dart';
import 'package:rive_api/src/model/model.dart';
import 'package:rive_api/src/manager/manager.dart';
import 'package:rive_api/src/api/api.dart';

class MockMeApi extends Mock implements MeApi {}

class MockVolumeApi extends Mock implements VolumeApi {}

void main() {
  Bus bus;
  MockMeApi meApi;
  MockVolumeApi volApi;

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

    volApi = MockVolumeApi();
    when(volApi.teams).thenAnswer(
      (i) => Future.value([
        Team(
            ownerId: 2,
            name: 'Team Vol 1',
            username: 'team_1',
            permission: 'owner'),
        Team(
            ownerId: 3,
            name: 'Team Vol 2',
            username: 'team_2',
            permission: 'member',
            avatarUrl: 'http://avatar.edu'),
      ]),
    );

    when(volApi.directoryTreeTeam(any)).thenAnswer(
      (i) => i.positionalArguments[0] == 2
          ? Future.value(DirectoryTree.fromFolderList([
              {'id': 1, 'name': 'Top Dir 1', 'parent': null, 'order': 0},
              {'id': 2, 'name': 'Top Dir 2', 'parent': null, 'order': 1},
              {'id': 3, 'name': 'Bottom Dir 1', 'parent': 1, 'order': 0},
              {'id': 4, 'name': 'Bottom Dir 2', 'parent': 1, 'order': 1},
              {'id': 5, 'name': 'Bottom Dir 3', 'parent': 2, 'order': 0},
            ]))
          : Future.value(DirectoryTree.fromFolderList([
              {'id': 6, 'name': 'Top Dir 1', 'parent': null, 'order': 0},
              {'id': 7, 'name': 'Top Dir 2', 'parent': null, 'order': 1},
              {'id': 8, 'name': 'Bottom Dir 1', 'parent': 1, 'order': 0},
            ])),
    );

    when(volApi.directoryTreeMe).thenAnswer(
      (i) => Future.value(DirectoryTree.fromFolderList([
        {'id': 1, 'name': 'Top Dir 1', 'parent': null, 'order': 0},
        {'id': 2, 'name': 'Bottom Dir 1', 'parent': 1, 'order': 0},
      ])),
    );
  });

  group('Bus', () {
    test('User data is routed correctly', () async {
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

    test('Volume data is routed correctly', () async {
      VolumeManager(
        volumeController: bus.volumeController,
        volumeApi: volApi,
        meApi: meApi,
      );
      final uiMock = bus.volumeStream;
      final c = Completer();

      uiMock.listen((vols) {
        expect(vols, isNotNull);
        expect(vols.length, 3);
        c.complete();
      });

      await c.future;
    });
  });
}
