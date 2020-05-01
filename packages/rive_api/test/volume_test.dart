import 'dart:async';

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'package:rive_api/src/model/model.dart';
import 'package:rive_api/src/view_model/view_model.dart';
import 'package:rive_api/src/manager/manager.dart';
import 'package:rive_api/src/api/api.dart';

class MockVolumeApi extends Mock implements VolumeApi {}

class MockMeApi extends Mock implements MeApi {}

void main() {
  MockMeApi mockMeApi;
  MockVolumeApi mockVolApi;

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
            name: 'Team Vol 1',
            username: 'team_1',
            permission: 'owner'),
        Team(
            ownerId: 2,
            name: 'Team Vol 2',
            username: 'team_2',
            permission: 'member',
            avatarUrl: 'http://avatar.edu'),
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
  });

  group('ViewModel', () {
    test('Volume view models are constructed correctly', () {
      final volume = VolumeVM(
        id: 1,
        name: 'Volume',
        type: VolumeType.team,
        treeStream: Stream<DirectoryTreeVM>.empty(),
      );
      expect(volume.name, 'Volume');
    });

    test('Volume view models are contructed correctly from Me models', () {
      final me = Me.testData();
      final volume = VolumeVM.fromMeModel(me, Stream<DirectoryTreeVM>.empty());

      expect(volume.id, 40955);
      expect(volume.name, 'Matt');
    });

    test('Volume view models are contructed correctly from Team models', () {
      final team = Team.testData();
      final volume =
          VolumeVM.fromTeamModel(team, Stream<DirectoryTreeVM>.empty());

      expect(volume.id, 12345);
      expect(volume.name, 'Team Awesome');
    });
  });

  /// These tests get complicated due to async and having to wait
  /// for events to roll through streams. In the UI, where things
  /// are async by nature, this complexity should not be there.

  group('Manager', () {
    test('Volume manager provides user volumes', () async {
      // Track async completion of the test
      final testComplete = Completer();

      final manager = VolumeManager(meApi: mockMeApi, volumeApi: mockVolApi);
      manager.volumesStream.listen((volumes) {
        expect(volumes.length, 3);
        expect(volumes.first.name, 'Matt');
        expect(volumes.last.name, 'Team Vol 2');
        expect(volumes.last.avatarUrl, 'http://avatar.edu');
        // Mark the test as completed
        testComplete.complete();
      });

      // Wait for the test to complete
      await testComplete.future;
    });

    test('Volume manager provides directory trees', () async {
      // Track async completion of the test
      final testsComplete = [Completer(), Completer()];

      final manager = VolumeManager(meApi: mockMeApi, volumeApi: mockVolApi);
      manager.volumesStream.listen((volumes) {
        expect(volumes.length, 3);
        volumes.first.treeStream.listen((tree) {
          expect(tree.tree.directories.first.name, 'Top Dir 1');
          // Mark the test as completed
          testsComplete.first.complete();
        });
        volumes.last.treeStream.listen((tree) {
          expect(tree.tree.directories.first.name, 'Top Dir 1');
          // Mark the test as completed
          testsComplete.last.complete();
        });
      });

      // Wait for the tests to complete
      await Future.wait(testsComplete.map((e) => e.future));
    });

    test('Volume manager updates active directory', () async {
      // Track config completion; streams need to be
      // listened to before firing stuff into sink
      final configComplete = [Completer(), Completer()];

      // Track async completion of the test
      final testComplete = Completer();

      final manager = VolumeManager(meApi: mockMeApi, volumeApi: mockVolApi);
      ;
      manager.volumesStream.listen((volumes) {
        volumes.first.treeStream.listen((tree) {
          if (!configComplete.first.isCompleted) {
            configComplete.first.complete();
          }
          // Mark the test as completed
          if (tree.activeDirectory != null) {
            expect(tree.activeDirectory.id, 1);
            testComplete.complete();
          }
        });
        volumes.last.treeStream.listen((tree) {
          if (!configComplete.last.isCompleted) {
            configComplete.last.complete();
          }
          expect(tree.tree.directories.first.name, 'Top Dir 1');
          if (tree.activeDirectory != null) {
            throw Exception('This is unexpected');
          }
        });
      });

      // Wait for config to complete
      await Future.wait(configComplete.map((e) => e.future));

      final activeDir = DirectoryVM(id: 1, name: 'Top Dir 1');
      manager.activeDirSink.add(activeDir);

      // Wait for the tests to complete
      await testComplete.future;
    });
  });
}
