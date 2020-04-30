import 'dart:async';
import 'dart:convert';

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
  MockVolumeApi mockVolumeApi;

  setUp(() {
    mockMeApi = MockMeApi();
    when(mockMeApi.whoami).thenAnswer(
      (i) => Future.value(
        Me(name: 'Matt', avatarUrl: 'http://example.avatar.com'),
      ),
    );

    mockVolumeApi = MockVolumeApi();
    when(mockVolumeApi.volumes).thenAnswer(
      (i) => Future.value([
        Volume(id: 1, name: 'My Files'),
        Volume(id: 2, name: 'Team Awesome'),
        Volume(id: 3, name: 'Team Dastardly', avatarUrl: 'http://avatar.edu'),
      ]),
    );
  });

  tearDown(() {});

  group('Model', () {
    test('Conductor wires up active directory events', () async {
      final volumeManager = VolumeManager();
      final activeDirManager = ActiveDirectoryManager();
      final conductor = Conductor(
          volumeManager: volumeManager, activeDirManager: activeDirManager);
      final dir = DirectoryVM(id: 0, name: 'Test Dir');

      final testComplete = Completer();

      activeDirManager.activeDirStream.listen((d) {
        print('Ohhhh a dir: $d');
        if (!testComplete.isCompleted) {
          testComplete.complete();
        }
      });
      // activeDirManager.activeDirSink.add(dir);
      conductor.activeDirSink.add(dir);

      await testComplete.future;
    }, timeout: const Timeout(Duration(milliseconds: 500)));
  });
}
