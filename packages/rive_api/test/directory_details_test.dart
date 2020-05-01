import 'dart:async';
import 'package:rive_api/src/api/file.dart';
import 'package:rive_api/src/manager/directory_details.dart';
import 'package:rive_api/src/view_model/view_model.dart';
import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

import 'package:mockito/mockito.dart';
import 'package:rive_api/src/model/model.dart';
import 'package:rive_api/src/api/api.dart';

class MockFileApi extends Mock implements FileApi {}

class MockVolumeApi extends Mock implements VolumeApi {}

final directoryA = Directory(
  id: 1,
  ownerId: 1,
  name: 'Level 1',
  children: [],
);
final directoryB = Directory(
  id: 1,
  ownerId: 1,
  name: 'Home dir',
  children: [directoryA],
);

void main() {
  MockFileApi mockFileApi;

  setUp(() {
    mockFileApi = MockFileApi();
    when(mockFileApi.getFiles(any)).thenAnswer((i) {
      final dir = i.positionalArguments[0] as Directory;
      return Future.value([
        File(id: 1, ownerId: dir.ownerId),
        File(id: 2, ownerId: dir.ownerId),
        File(id: 3, ownerId: dir.ownerId),
        File(id: 4, ownerId: dir.ownerId),
      ]);
    });
    when(mockFileApi.getFileDetails(any, any)).thenAnswer((i) {
      final dir = i.positionalArguments[0] as Directory;
      final fileIds = i.positionalArguments[1] as List<int>;
      final output = fileIds.map((id) => File(
            id: 1,
            name: '$id ${dir.ownerId}',
            ownerId: dir.ownerId,
            preview: 'preview $id ${dir.ownerId}',
          ));
      return Future.value(output);
    });
  });
  group('Manager', () {
    test('Active Directory Manager provides directories files', () async {
      // Track async completion of the test
      final testComplete = Completer();
      final activeDirController = BehaviorSubject<DirectoryVM>();
      final filesController = BehaviorSubject<Iterable<FileVM>>();
      final manager = DirectoryDetailsManager(
        fileApi: mockFileApi,
        activeDirController: activeDirController,
        activeDirectoryFilesController: filesController,
      );
      final checks = [
        (List<FileVM> list) => list.length == 0,
        (List<FileVM> list) => list.length == 4,
      ];
      manager.filesStream.listen((Iterable<FileVM> files) {
        checks.removeAt(0);
        if (checks.length == 0) {
          testComplete.complete();
        }
      });

      var activeDirectory = DirectoryVM.fromModel(directoryA);
      activeDirController.add(activeDirectory);

      // Wait for the test to complete
      await testComplete.future;
    });

    test('Active Directory Manager caches directories', () async {
      // Track async completion of the test
      final testComplete = Completer();
      final activeDirController = BehaviorSubject<DirectoryVM>();
      final filesController = BehaviorSubject<Iterable<FileVM>>();
      final manager = DirectoryDetailsManager(
        fileApi: mockFileApi,
        activeDirController: activeDirController,
        activeDirectoryFilesController: filesController,
      );
      final checks = [
        (List<FileVM> list) => list.length == 0,
        (List<FileVM> list) => list.length == 4,
        (List<FileVM> list) => list.length == 0,
        (List<FileVM> list) => list.length == 4,
        (List<FileVM> list) => list.length == 4,
        (List<FileVM> list) => list.length == 4,
      ];
      manager.filesStream.listen((Iterable<FileVM> files) {
        checks.removeAt(0);
        if (checks.length == 0) {
          testComplete.complete();
        }
      });

      var activeDirectory = DirectoryVM.fromModel(directoryA);
      var activeDirectoryB = DirectoryVM.fromModel(directoryB);
      activeDirController.add(activeDirectory);
      activeDirController.add(activeDirectoryB);
      activeDirController.add(activeDirectory);

      // Wait for the test to complete
      await testComplete.future;
    });
  });
}
