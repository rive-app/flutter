import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/src/api/api.dart';
import 'package:rive_api/src/data_model/data_model.dart';
import 'package:rive_api/src/model/model.dart';
import 'package:rive_api/src/plumber.dart';

import 'fixtures/api_responses.dart';
import 'fixtures/data_models.dart';

class MockFileApi extends Mock implements FileApi {}

class MockFolderApi extends Mock implements FolderApi {}

void main() {
  group('FolderContents Manager ', () {
    Plumber _plumber;
    MockFileApi _mockedFileApi;
    MockFolderApi _mockedFolderApi;
    FolderContentsManager _folderContentsManager;
    setUp(() {
      _plumber = Plumber();

      // Set up the 'Me' message.
      _plumber.message(Me.fromDM(getMe()));
      _mockedFileApi = MockFileApi();
      _mockedFolderApi = MockFolderApi();
      _folderContentsManager = FolderContentsManager.tester(
        _mockedFileApi,
        _mockedFolderApi,
      );

      // 'Your Files' folder.
      when(_mockedFileApi.myFiles(1)).thenAnswer((_) async {
        final data = json.decode(myFilesResponse) as List<Object>;
        return FileDM.fromIdList(data, null);
      });

      // File details for the files returned above.
      when(_mockedFileApi.getFileDetails([1, 2])).thenAnswer((_) async {
        final data = json.decode(myFilesDetailsResponse);
        final cdn = CdnDM.fromData(data['cdn']);
        return FileDM.fromDataList(data['files'], cdn);
      });

      // Get all my folders.
      when(_mockedFolderApi.myFolders()).thenAnswer((_) async {
        final data = json.decode(myFoldersResponse) as Map<String, Object>;
        return FolderDM.fromDataList(data['folders']);
      });
    });

    tearDown(() {
      Plumber().reset();
    });

    test('Load folder contents', () async {
      final testComplete = Completer();

      _plumber.getStream<FolderContents>().listen((contents) {
        expect(contents.files.length, 2);
        testComplete.complete();
      });

      await testComplete.future;
    });

    test('Load File details', () async {
      final testComplete = Completer();

      _plumber.getStream<File>('1').listen((fileDetails) {
        expect(fileDetails.ownerId, 12345);
        expect(fileDetails.id, 1);

        testComplete.complete();
      });

      await testComplete.future;
    });
  });
}
