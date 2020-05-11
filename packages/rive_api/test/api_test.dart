import 'package:mockito/mockito.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rive_api/src/api/api.dart';

import 'fixtures/api_responses.dart';
import 'fixtures/data_models.dart';

class MockRiveApi extends Mock implements RiveApi {
  final host = '';
}

void main() {
  group('Me', () {
    test('load me details api', () async {
      final riveApi = MockRiveApi();
      when(riveApi.getFromPath('/api/me'))
          .thenAnswer((_) async => successMeResponse);
      final mockApi = MeApi(riveApi);
      final me = await mockApi.whoami;

      expect(me.signedIn, true);
      expect(me.id, 40839);
      expect(me.ownerId, 40839);
      expect(me.name, 'MaxMax');
      expect(me.username, 'maxmax');
      expect(me.avatarUrl, null);
      expect(me.isAdmin, false);
      expect(me.isPaid, false);
      expect(me.notificationCount, 5);
      expect(me.verified, true);
    });

    test('load me details api fails if not logged in', () {
      final riveApi = MockRiveApi();
      when(riveApi.getFromPath('/api/me'))
          .thenAnswer((_) async => failureMeResponse);
      final mockApi = MeApi(riveApi);
      expect(mockApi.whoami, throwsException);
    });
  });

  group('Team', () {
    test('load teams', () async {
      final riveApi = MockRiveApi();
      when(riveApi.getFromPath('/api/teams'))
          .thenAnswer((_) async => successTeamsResponse);
      final mockApi = TeamApi(riveApi);
      final teams = await mockApi.teams;

      expect(teams.length, 2);
      expect(teams.first.ownerId, 41545);
      expect(teams.first.name, 'Team Titans');
      expect(teams.first.username, 'team_titans');
      expect(teams.first.avatarUrl,
          'https://cdn.2dimensions.com/avatars/krypton-41545-b131305f-6aba-4fe5-b797-a10035143fa0');
      expect(teams.first.permission, 'Owner');
      expect(teams.last.ownerId, 41576);
      expect(teams.last.name, 'Avengers');
      expect(teams.last.username, 'avengers_101');
      expect(teams.last.avatarUrl, null);
      expect(teams.last.permission, 'Member');
    });
  });

  group('User', () {
    test('serach users', () async {
      final riveApi = MockRiveApi();
      when(riveApi.getFromPath('/api/search/ac/avatar_artists/i'))
          .thenAnswer((_) async => successSearchResponse);
      final mockApi = UserApi(riveApi);
      final users = await mockApi.search('i');

      expect(users.length, 3);
      expect(users.first.ownerId, 40981);
      expect(users.first.name, null);
      expect(users.first.username, 'Mike');
      expect(users.first.avatarUrl, null);
      expect(users.last.ownerId, 16479);
      expect(users.last.name, 'Luigi Rosso');
      expect(users.last.username, 'castor');
      expect(users.last.avatarUrl,
          'https://cdn.2dimensions.com/avatars/16479-1-1547266294-krypton');
    });
  });

  group('Folder', () {
    test('get user folders', () async {
      final riveApi = MockRiveApi();
      when(riveApi.getFromPath('/api/my/files/folders'))
          .thenAnswer((_) async => successFoldersResponse);
      final mockApi = FolderApi(riveApi);
      final me = getMe();
      final folders = await mockApi.folders(me);
      expect(folders.length, 4);
      folders.forEach((folder) {
        expect(folder.ownerId, null);
        expect(folder.order != null, true);
        expect(folder.id != null, true);
      });
    });

    test('get team folders', () async {
      final riveApi = MockRiveApi();
      when(riveApi.getFromPath('/api/teams/3/folders'))
          .thenAnswer((_) async => successTeamFoldersResponse);
      final mockApi = FolderApi(riveApi);
      final team = getTeam();
      final folders = await mockApi.folders(team);
      expect(folders.length, 2);
      folders.forEach((folder) {
        expect(folder.ownerId, 3);
        expect(folder.order != null, true);
        expect(folder.id != null, true);
      });
    });
  });

  group('Files', () {
    test('get user files', () async {
      final riveApi = MockRiveApi();
      when(riveApi.get('/api/my/files/a-z/rive/1'))
          .thenAnswer((_) async => successFilesResponse);
      final mockApi = FileApi(riveApi);
      final me = getMe();
      final folder = getFolder(me);
      final files = await mockApi.getFiles(folder.id, ownerId: folder.ownerId);
      expect(files.length, 16);
      files.forEach((file) {
        expect(file.id != null, true);
        expect(file.name, null);
        expect(file.ownerId, null);
        expect(file.preview, null);
      });
    });

    test('get user file details', () async {
      final riveApi = MockRiveApi();
      when(riveApi.post('/api/my/files', body: "[1,2,3]"))
          .thenAnswer((_) async => successFileDetailsResponse);
      final mockApi = FileApi(riveApi);
      final me = getMe();
      final folder = getFolder(me);
      final files =
          await mockApi.getFileDetails([1, 2, 3], ownerId: folder.ownerId);
      expect(files.length, 3);
      files.forEach((file) {
        expect(file.id != null, true);
        expect(file.name != null, true);
        expect(file.ownerId, 1);
        expect(file.preview != null, true);
      });
      expect(files.first.name, 'New File');
      expect(files.first.preview, 'http://foofo.com/<preview>?param');
      expect(files.last.name, 'New File 3');
      expect(files.last.preview, 'http://foofo.com/<preview3>?param');
    });

    test('get team files', () async {
      final riveApi = MockRiveApi();
      when(riveApi.get('/api/teams/3/files/a-z/rive/1'))
          .thenAnswer((_) async => successFilesResponse);
      final mockApi = FileApi(riveApi);
      final team = getTeam();
      final folder = getFolder(team);
      final files = await mockApi.getFiles(folder.id, ownerId: folder.ownerId);
      expect(files.length, 16);
      files.forEach((file) {
        expect(file.id != null, true);
        expect(file.name, null);
        expect(file.ownerId, 3);
        expect(file.preview, null);
      });
    });

    test('get team file details', () async {
      final riveApi = MockRiveApi();
      when(riveApi.post('/api/teams/3/files', body: "[1,2,3]"))
          .thenAnswer((_) async => successFileDetailsResponse);
      final mockApi = FileApi(riveApi);
      final team = getTeam();
      final folder = getFolder(team);
      final files =
          await mockApi.getFileDetails([1, 2, 3], ownerId: folder.ownerId);
      expect(files.length, 3);
      files.forEach((file) {
        expect(file.id != null, true);
        expect(file.name != null, true);
        expect(file.ownerId, 1);
        expect(file.preview != null, true);
      });
      expect(files.first.name, 'New File');
      expect(files.first.preview, 'http://foofo.com/<preview>?param');
      expect(files.last.name, 'New File 3');
      expect(files.last.preview, 'http://foofo.com/<preview3>?param');
    });
  });
}
