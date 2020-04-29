import 'dart:async';

/// Me tests
import 'dart:convert';
import 'package:mockito/mockito.dart';

import 'package:test/test.dart';
import 'package:rive_api/src/model/volume.dart';
import 'package:rive_api/src/manager/volume.dart';
import 'package:rive_api/src/api/api.dart';

void main() {
  group('Model', () {
    test('Volume models are constructed correctly', () {
      final volume = Volume(name: 'Volume');
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

  group('Manager', () {
    test(
      'Me manager provides logged in user data',
      () async {
        // Mock out the api
        final mockApi = MockVolumeApi();
        when(mockApi.volumes).thenAnswer(
          (i) => Future.value([
            Volume(name: 'Matt Vol'),
            Volume(name: 'Team Vol 1'),
            Volume(name: 'Team Vol 2', avatarUrl: 'http://avatar.edu'),
          ]),
        );

        // Track async completion of the test
        final testComplete = Completer();

        final manager = VolumeManager(mockApi);
        manager.volumes.listen((volumes) {
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
      },
      timeout: const Timeout(Duration(milliseconds: 500)),
    );
  });
}

/*
 * Mocks
 */
class MockVolumeApi extends Mock implements VolumeApi {}
