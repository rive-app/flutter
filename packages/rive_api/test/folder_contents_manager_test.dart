import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/data_model.dart';
import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/plumber.dart';

import 'package:utilities/utilities.dart';

import 'fixtures/api_responses.dart';
import 'fixtures/data_models.dart';

class MockFileApi extends Mock implements FileApi {}

class MockFolderApi extends Mock implements FolderApi {}

void main() {
  group('FolderContents Manager', () {
    Plumber _plumber;
    MockFileApi _mockedFileApi;
    MockFolderApi _mockedFolderApi;
    // ignore: unused_local_variable
    FolderContentsManager _folderContentsManager;

    setUp(() {
      _plumber = Plumber();

      // Set up the 'Me' message.
      final meDm = getMe();
      final me = Me.fromDM(getMe());
      final folder = Folder.fromDM(getFolder(meDm));
      _plumber.message<Me>(me);
      _mockedFileApi = MockFileApi();
      _mockedFolderApi = MockFolderApi();
      _folderContentsManager = FolderContentsManager.tester(
        _mockedFileApi,
        _mockedFolderApi,
      );

      // Load the user's directory
      _plumber.message<CurrentDirectory>(CurrentDirectory(me, folder));

      // 'Your Files' folder.
      when(_mockedFileApi.files(2, 1)).thenAnswer((_) async {
        final data = json.decodeList<int>(myFilesResponse);
        // print("Mock file api $data");
        var res = FileDM.fromIdList(data, 40836);
        // print("Res $res");
        return res;
      });

      // Team file details for the files returned above.
      when(_mockedFileApi.fileDetails(any)).thenAnswer((_) async {
        final data = json.decodeMap(myFilesDetailsResponse);
        final cdn = CdnDM.fromData(data.getMap<String, dynamic>('cdn'));
        // print("Mock file api2 $data");
        return FileDM.fromDataList(data.getList('files'), {'CDN': cdn});
      });

      // My file details for the files returned above.
      when(_mockedFileApi.fileDetails(any)).thenAnswer((_) async {
        final data = json.decodeMap(myFilesDetailsResponse);
        final cdn = CdnDM.fromData(data.getMap<String, dynamic>('cdn'));
        // print("Mock file api2 $data");
        return FileDM.fromDataList(data.getList('files'), {'CDN': cdn});
      });

      // Get all my folders.
      when(_mockedFolderApi.folders(any)).thenAnswer((_) async {
        final data = json.decode(myFoldersResponse) as Map<String, Object>;
        return FolderDM.fromDataList(data.getList('folders'), 40836);
      });
    });

    tearDown(() {
      Plumber().reset();
    });

    test('Load folder contents', () async {
      final testComplete = Completer<void>();

      final checks = [
        (FolderContents cts) => cts.files == null && cts.folders == null,
        (FolderContents cts) => cts.files.length == 2,
      ];

      final me = _plumber.peek<Me>();
      const firstFolderId = 1;
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
      final testComplete = Completer<void>();
      _plumber
          .getStream<File>(File(id: 1, ownerId: 40836).hashCode)
          .listen((fileDetails) {
        expect(fileDetails.ownerId, 40836);
        expect(fileDetails.id, 1);

        testComplete.complete();
      });

      await testComplete.future;
    });
  });
}
