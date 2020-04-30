import 'dart:async';
import 'dart:convert';

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'package:rive_api/src/model/model.dart';
import 'package:rive_api/src/view_model/view_model.dart';
import 'package:rive_api/src/manager/manager.dart';
import 'package:rive_api/src/api/api.dart';

class MockVolumeApi extends Mock implements VolumeApi {}

void main() {
  group('Model', () {
    test('Volume models are constructed correctly', () {
      final volume = Volume(id: 1, name: 'Volume');
      expect(volume.name, 'Volume');
    });

    test('Volume models are contructed correctly from json', () {
      var jsonVolume = json.encode({'name': 'Volume'});
      var volume = Volume.fromData(json.decode(jsonVolume));

      expect(volume.name, 'Volume');
      expect(volume.hasAvatar, false);

      jsonVolume =
          json.encode({'name': 'Volume 1', 'avatar': 'http://avatar.com'});
      volume = Volume.fromData(json.decode(jsonVolume));

      expect(volume.name, 'Volume 1');
      expect(volume.hasAvatar, true);
      expect(volume.avatarUrl, 'http://avatar.com');
    });

    test('Volume models are contructed correctly from a json list', () {
      final jsonVolumes = json.encode([
        {'name': 'Volume 1'},
        {'name': 'Volume 2'},
      ]);
      final volumes = Volume.fromDataList(json.decode(jsonVolumes));

      expect(volumes.length, 2);
      expect(volumes.first.name, 'Volume 1');
      expect(volumes.last.name, 'Volume 2');
    });
  });

  /// These tests get complicated due to async and having to wait
  /// for events to roll through streams. In the UI, where things
  /// are async by nature, this complexity should not be there.

  group('Manager', () {
    test('Volume manager provides user volumes', () async {
      // Mock out the api
      final mockApi = MockVolumeApi();
      when(mockApi.volumes).thenAnswer(
        (i) => Future.value([
          Volume(id: 1, name: 'Matt Vol'),
          Volume(id: 2, name: 'Team Vol 1'),
          Volume(id: 3, name: 'Team Vol 2', avatarUrl: 'http://avatar.edu'),
        ]),
      );

      // Track async completion of the test
      final testComplete = Completer();

      final manager = VolumeManager(mockApi);
      manager.volumesStream.listen((volumes) {
        expect(volumes.length, 3);
        expect(volumes.first.name, 'Matt Vol');
        expect(volumes.last.name, 'Team Vol 2');
        expect(volumes.last.avatarUrl, 'http://avatar.edu');
        // Mark the test as completed
        testComplete.complete();
      });

      // Wait for the test to complete
      await testComplete.future;

      manager.dispose();
    });

    test('Volume manager provides directory trees', () async {
      // Mock out the api
      final mockApi = MockVolumeApi();
      when(mockApi.volumes).thenAnswer(
        (i) => Future.value([
          Volume(id: 1, name: 'Matt Vol'),
          Volume(id: 2, name: 'Team Vol 1'),
          Volume(id: 3, name: 'Team Vol 2', avatarUrl: 'http://avatar.edu'),
        ]),
      );

      when(mockApi.directoryTree(any)).thenAnswer(
        (i) => Future.value(DirectoryTree.fromFolderList([
          {'id': 1, 'name': 'Top Dir 1', 'parent': null, 'order': 0},
          {'id': 2, 'name': 'Top Dir 2', 'parent': null, 'order': 1},
          {'id': 3, 'name': 'Bottom Dir 1', 'parent': 1, 'order': 0},
          {'id': 4, 'name': 'Bottom Dir 2', 'parent': 1, 'order': 1},
          {'id': 5, 'name': 'Bottom Dir 3', 'parent': 2, 'order': 0},
        ])),
      );

      // Track async completion of the test
      final testsComplete = [Completer(), Completer()];

      final manager = VolumeManager(mockApi);
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

      manager.dispose();
    });

    test('Volume manager updates active directory', () async {
      // Mock out the api
      final mockApi = MockVolumeApi();
      when(mockApi.volumes).thenAnswer(
        (i) => Future.value([
          Volume(id: 1, name: 'Matt Vol'),
          Volume(id: 2, name: 'Team Vol 1', avatarUrl: 'http://avatar.edu'),
        ]),
      );

      when(mockApi.directoryTree(any)).thenAnswer((i) {
        return i.positionalArguments[0].id == 1
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
              ]));
      });

      // Track config completion; streams need to be
      // listened to before firing stuff into sink
      final configComplete = [Completer(), Completer()];

      // Track async completion of the test
      final testComplete = Completer();

      final manager = VolumeManager(mockApi);
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

      manager.dispose();
    }, timeout: const Timeout(Duration(milliseconds: 500)));
  });
}
