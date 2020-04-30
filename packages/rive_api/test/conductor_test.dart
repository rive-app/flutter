import 'dart:async';

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'package:rive_api/src/model/model.dart';
import 'package:rive_api/src/view_model/view_model.dart';
import 'package:rive_api/src/manager/manager.dart';
import 'package:rive_api/src/api/api.dart';

// Mocks
class MockMeApi extends Mock implements MeApi {}

class MockVolumeApi extends Mock implements VolumeApi {}

void main() {
  MockMeApi mockMeApi;
  MockVolumeApi mockVolApi;
  DirectoryVM testDir;

  setUp(() {
    mockMeApi = MockMeApi();
    when(mockMeApi.whoami).thenAnswer(
      (_) => Future.value(
        Me(ownerId: 3, id: 1, name: 'Matt', signedIn: true),
      ),
    );
    mockVolApi = MockVolumeApi();
    when(mockVolApi.teams).thenAnswer(
      (i) => Future.value([
        Team(
            ownerId: 1,
            name: 'Matt Vol 1',
            username: 'matt 1',
            permission: 'owner'),
        Team(
            ownerId: 2,
            name: 'Matt Vol 2',
            username: 'matt 2',
            permission: 'member'),
      ]),
    );

    when(mockVolApi.directoryTreeTeam(any)).thenAnswer(
      (i) => i.positionalArguments[0] == 1
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
    when(mockVolApi.directoryTreeMe).thenAnswer(
      (i) => Future.value(DirectoryTree.fromFolderList([
        {'id': 1, 'name': 'Top Dir 1', 'parent': null, 'order': 0},
        {'id': 2, 'name': 'Bottom Dir 1', 'parent': 1, 'order': 0},
      ])),
    );

    testDir = DirectoryVM(id: 6, name: 'Top Dir 1');
  });

  tearDown(() {});

  /// Another nice side effect of the conductor is that it acts as a central
  /// point for end to end testing of sinks and streams that span multiple managers.

  group('Model', () {
    test('Conductor passes an active directory to managers', () async {
      final volumeManager = VolumeManager();
      final activeDirManager = ActiveDirectoryManager();
      final conductor = Conductor(
        volumeManager: volumeManager,
        activeDirManager: activeDirManager,
      );
      final dir = DirectoryVM(id: 0, name: 'Test Dir');

      final testComplete = Completer();

      activeDirManager.activeDirStream.listen((d) {
        expect(d.id, 0);
        testComplete.complete();
      });
      // activeDirManager.activeDirSink.add(dir);
      conductor.activeDirSink.add(dir);

      await testComplete.future;
    }, timeout: const Timeout(Duration(milliseconds: 500)));

    test('Conductor receives and forwards active directory to managers',
        () async {
      // Managers
      final volumeManager =
          VolumeManager(meApi: mockMeApi, volumeApi: mockVolApi);
      final activeDirManager = ActiveDirectoryManager();
      Conductor(
        volumeManager: volumeManager,
        activeDirManager: activeDirManager,
      );

      final testComplete = Completer();

      // If we push a new active dir from the active dir
      // manager, then the volume manager should flag
      // the matching dir as active in the directory tree

      // Listen to the volume manager to get the streams
      // for the directory tree streams
      volumeManager.volumesStream.listen((vols) {
        // Listen to the second tree as that's where
        // we expect the active dir to land
        vols.last.treeStream.listen((tree) {
          if (tree.activeDirectory != null) {
            expect(tree.activeDirectory.id, 6);
            testComplete.complete();
          }
        });
      });
      activeDirManager.activeDirSink.add(testDir);

      await testComplete.future;
    });
  });
}
