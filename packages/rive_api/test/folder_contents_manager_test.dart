import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/data_model.dart';
import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/plumber.dart';

import 'fixtures/api_responses.dart';
import 'fixtures/data_models.dart';

import 'package:utilities/utilities.dart';

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
      _plumber.message<Me>(Me.fromDM(getMe()));
      _mockedFileApi = MockFileApi();
      _mockedFolderApi = MockFolderApi();
      _folderContentsManager = FolderContentsManager.tester(
        _mockedFileApi,
        _mockedFolderApi,
      );

      // 'Your Files' folder.
      when(_mockedFileApi.myFiles(2, 1)).thenAnswer((_) async {
        final data = json.decode(myFilesResponse) as List<dynamic>;
        // print("Mock file api $data");
        var res = FileDM.fromIdList(data, 40836);
        // print("Res $res");
        return res;
      });

      // Team file details for the files returned above.
      when(_mockedFileApi.teamFileDetails(any, any)).thenAnswer((_) async {
        final data = json.decode(myFilesDetailsResponse);
        final cdn = CdnDM.fromData(data['cdn']);
        // print("Mock file api2 $data");
        return FileDM.fromDataList(data['files'], cdn);
      });

      // My file details for the files returned above.
      when(_mockedFileApi.myFileDetails(any)).thenAnswer((_) async {
        final data = json.decode(myFilesDetailsResponse);
        final cdn = CdnDM.fromData(data['cdn']);
        // print("Mock file api2 $data");
        return FileDM.fromDataList(data['files'], cdn);
      });

      // Get all my folders.
      when(_mockedFolderApi.myFolders(any)).thenAnswer((_) async {
        final data = json.decode(myFoldersResponse) as Map<String, Object>;
        return FolderDM.fromDataList(data['folders'], 40836);
      });
    });

    tearDown(() {
      Plumber().reset();
    });

    test('Load folder contents', () async {
      final testComplete = Completer();

      final checks = [
        (FolderContents cts) => cts.files == null && cts.folders == null,
        (FolderContents cts) => cts.files.length == 2,
      ];

      final me = _plumber.peek<Me>();
      final firstFolderId = 1;
      final folderContentsId = szudzik(me.ownerId, firstFolderId);

      _plumber.getStream<FolderContents>(folderContentsId).listen((contents) {
        var check = checks.removeAt(0);
        expect(check(contents), true);
        if (checks.isEmpty) {
          testComplete.complete();
        }
      });

      await testComplete.future;
    });

    test('Load File details', () async {
      final testComplete = Completer();
      _plumber
          .getStream<File>(File(id: 1, ownerId: 12345).hashCode)
          .listen((fileDetails) {
        expect(fileDetails.ownerId, 12345);
        expect(fileDetails.id, 1);

        testComplete.complete();
      });

      await testComplete.future;
    });
  });
}
