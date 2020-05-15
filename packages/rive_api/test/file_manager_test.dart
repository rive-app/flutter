@Timeout(const Duration(seconds: 1))
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/data_model.dart';
import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/plumber.dart';

import 'fixtures/data_models.dart';
import 'helpers/test_helpers.dart';

class MockFileApi extends Mock implements FileApi {
  final host = '';
}

class MockFolderApi extends Mock implements FolderApi {
  final host = '';
}

void main() {
  group('File Manager ', () {
    MockFileApi mockedFileApi;
    MockFolderApi mockedFolderApi;
    FileManager fileManager;
    MeDM meDm;
    Me me;
    MeDM altMeDM;
    Me altMe;
    List<TeamDM> teamDMs;
    List<Team> teams;
    setUp(() {
      mockedFileApi = MockFileApi();
      mockedFolderApi = MockFolderApi();
      meDm = getMe();
      me = Me.fromDM(meDm);
      altMeDM = getMe(ownerId: 10);
      altMe = Me.fromDM(altMeDM);
      teamDMs = [
        getTeam(ownerId: 15),
        getTeam(ownerId: 16),
        getTeam(ownerId: 17)
      ];
      teams = teamDMs.map((teamDM) {
        when(mockedFolderApi.folders(teamDM))
            .thenAnswer((_) async => getFoldersDM(teamDM));
        return Team.fromDM(teamDM);
      }).toList();

      when(mockedFolderApi.folders(meDm))
          .thenAnswer((_) async => getFoldersDM(meDm));
      when(mockedFolderApi.folders(altMeDM))
          .thenAnswer((_) async => getFoldersDM(altMeDM));

      fileManager = FileManager.tester(mockedFileApi, mockedFolderApi);
    });
    tearDown(() {
      Plumber().reset();
    });

    test('new me', () async {
      final meFolderCompleter = Completer();
      final generalFolderCompleter = Completer();
      Plumber().getStream<List<Folder>>(me.hashCode).listen((folders) {
        expect(folders.length, 2);
        meFolderCompleter.complete();
      });
      Plumber().getStream<Map<Owner, List<Folder>>>().listen((folderMap) {
        expect(folderMap.keys.length, 1);
        expect(folderMap[me].length, 2);
        generalFolderCompleter.complete();
      });
      Plumber().message(me);
      await meFolderCompleter.future;
      await generalFolderCompleter.future;
    });
    test('me, clears with new me, stays with old me', () async {
      final meCompleter = testStream(
        Plumber().getStream<List<Folder>>(me.hashCode),
        [
          (List<Folder> folders) => folders?.length == 2,
          (List<Folder> folders) => folders == null,
        ],
      );

      final altMeCompleter =
          testStream(Plumber().getStream<List<Folder>>(altMe.hashCode), [
        (List<Folder> folders) => folders?.length == 2,
        (List<Folder> folders) => folders?.length == 2,
      ]);

      final generalCompleter =
          testStream(Plumber().getStream<Map<Owner, List<Folder>>>(), [
        (Map<Owner, List<Folder>> folderMap) => folderMap.keys.length == 1,
        (Map<Owner, List<Folder>> folderMap) => folderMap == null,
        (Map<Owner, List<Folder>> folderMap) => folderMap.keys.length == 1,
        (Map<Owner, List<Folder>> folderMap) => folderMap.keys.length == 1,
      ]);

      Plumber().message(me);
      // NOTE: gotta force a bit of an order, or its gets unpredictable
      await new Future.delayed(const Duration(milliseconds: 10));
      Plumber().message(altMe);
      await new Future.delayed(const Duration(milliseconds: 10));
      Plumber().message(altMe);
      await meCompleter.future;
      await altMeCompleter.future;
      await generalCompleter.future;
    });
    test('new teams', () async {
      final firstTeamCompleter =
          testStream(Plumber().getStream<List<Folder>>(teams[0].hashCode), [
        (List<Folder> folders) => folders?.length == 2,
      ]);

      // NOTE: this is a bit dumb.
      // we totally have a race condition here
      // if things happen more spaced out we'd expect to see 0,1,2,3 here
      final generalCompleter =
          testStream(Plumber().getStream<Map<Owner, List<Folder>>>(), [
        (Map<Owner, List<Folder>> folderMap) => folderMap.keys.length == 0,
        (Map<Owner, List<Folder>> folderMap) => folderMap.keys.length == 3,
        (Map<Owner, List<Folder>> folderMap) => folderMap.keys.length == 3,
        (Map<Owner, List<Folder>> folderMap) => folderMap.keys.length == 3,
      ]);

      Plumber().message(teams);

      await firstTeamCompleter.future;
      await generalCompleter.future;
    });
    test('teams updated', () async {
      final firstTeamCompleter =
          testStream(Plumber().getStream<List<Folder>>(teams[0].hashCode), [
        (List<Folder> folders) => folders?.length == 2,
        (List<Folder> folders) => folders == null,
      ]);

      final secondTeamCompleter =
          testStream(Plumber().getStream<List<Folder>>(teams[1].hashCode), [
        (List<Folder> folders) => folders?.length == 2,
        (List<Folder> folders) => folders?.length == 2,
      ]);

      // NOTE: this is a bit dumb.
      // we totally have a race condition here
      // if things happen more spaced out we'd expect to see 0,1,2,3 here
      final generalCompleter =
          testStream(Plumber().getStream<Map<Owner, List<Folder>>>(), [
        // initialize list
        (Map<Owner, List<Folder>> folderMap) => folderMap.keys.length == 0,
        // all 3 teams load real close together
        (Map<Owner, List<Folder>> folderMap) => folderMap.keys.length == 3,
        (Map<Owner, List<Folder>> folderMap) => folderMap.keys.length == 3,
        (Map<Owner, List<Folder>> folderMap) => folderMap.keys.length == 3,
        // update teams
        (Map<Owner, List<Folder>> folderMap) => folderMap.keys.length == 2,
        // load the 2 teams
        (Map<Owner, List<Folder>> folderMap) => folderMap.keys.length == 2,
        (Map<Owner, List<Folder>> folderMap) => folderMap.keys.length == 2,
      ]);

      Plumber().message(teams);

      await new Future.delayed(const Duration(milliseconds: 10));
      Plumber().message(teams.sublist(1));
      await firstTeamCompleter.future;
      await generalCompleter.future;
      await secondTeamCompleter.future;
    });
  });
}

class Folders {}
