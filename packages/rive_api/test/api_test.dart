import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/data_model.dart';
import 'package:rive_api/models/team_invite_status.dart';

import 'fixtures/api_responses.dart';
import 'fixtures/data_models.dart';

class MockRiveApi extends Mock implements RiveApi {
  @override
  final host = '';

  @override
  Future<void> clearCookies() {
    // TODO: implement clearCookies
    cookiesCleared = true;
    return Future.value();
  }

  bool cookiesCleared = false;

  @override
  final cookies = <String, String>{};
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

    test('load me details api fails if not logged in', () async {
      final riveApi = MockRiveApi();
      when(riveApi.getFromPath('/api/me'))
          .thenAnswer((_) async => failureMeResponse);
      final mockApi = MeApi(riveApi);
      final nullResponse = await mockApi.whoami;
      expect(nullResponse, null);
    });

    test('signout successful', () async {
      final riveApi = MockRiveApi();
      expect(riveApi.cookiesCleared, false);
      when(riveApi.getFromPath('/signout'))
          .thenAnswer((_) async => successLogoutResponse);
      final mockApi = MeApi(riveApi);
      expect(await mockApi.signout(), true);
      expect(riveApi.cookiesCleared, true);
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

    test('load teams members', () async {
      final riveApi = MockRiveApi();
      when(riveApi.getFromPath('/api/teams/41545/affiliates'))
          .thenAnswer((_) async => successTeamAffiliatesResponse);
      final mockApi = TeamApi(riveApi);
      final teams = await mockApi.teamMembers(41545);

      expect(teams.length, 2);
      expect(teams.first.ownerId, 40944);
      expect(teams.first.name, null);
      expect(teams.first.username, 'foofoo');
      expect(teams.first.avatarUrl, null);
      expect(teams.first.permission, 'Owner');
      expect(teams.first.status, TeamInviteStatus.accepted);
      expect(teams.last.ownerId, 41594);
      expect(teams.last.name, null);
      expect(teams.last.username, 'mightymax');
      expect(teams.last.avatarUrl, null);
      expect(teams.last.permission, 'Member');
      expect(teams.last.status, TeamInviteStatus.pending);
    });
  });

  group('User', () {
    test('search users', () async {
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
      when(riveApi.getFromPath('/api/folders/2'))
          .thenAnswer((_) async => successFoldersResponse);
      final mockApi = FolderApi(riveApi);
      final me = getMe();
      final folders = await mockApi.folders(me);
      expect(folders.length, 5);
      folders.forEach((folder) {
        expect(folder.ownerId, 2);
        expect(folder.order != null, true);
        expect(folder.id != null, true);
      });
    });

    test('get team folders', () async {
      final riveApi = MockRiveApi();
      when(riveApi.getFromPath('/api/folders/3'))
          .thenAnswer((_) async => successTeamFoldersResponse);
      final mockApi = FolderApi(riveApi);
      final team = getTeam();
      final folders = await mockApi.folders(team);
      expect(folders.length, 4);
      folders.forEach((folder) {
        expect(folder.ownerId, 3);
        expect(folder.order != null, true);
        expect(folder.id != null, true);
      });
    });

    test('get create user folder', () async {
      final riveApi = MockRiveApi();
      when(riveApi.post('/api/folders/1',
              body: '{"name":"New Folder","order":0,"parent":1}'))
          .thenAnswer((_) async {
        return successFolderCreationResponse;
      });
      final mockApi = FolderApi(riveApi);
      final newFolder = await mockApi.createFolder(1, 1);
      expect(newFolder.name, 'New Folder');
      expect(newFolder.id, 10);
      expect(newFolder.parent, -1);
      expect(newFolder.order, 0);
      expect(newFolder.ownerId, 1);
    });

    test('get create team folder', () async {
      final riveApi = MockRiveApi();
      final team = getTeam();
      const folderId = 10;
      when(riveApi.post('/api/folders/${team.ownerId}',
              body: '{"name":"New Folder","order":0,"parent":10}'))
          .thenAnswer((_) async => successTeamFolderCreationResponse);
      final mockApi = FolderApi(riveApi);

      final newFolder = await mockApi.createFolder(team.ownerId, folderId);
      expect(newFolder.name, 'New Folder');
      expect(newFolder.id, 10);
      expect(newFolder.parent, -1);
      expect(newFolder.order, 1);
      expect(newFolder.ownerId, 3);
    });
  });

  group('Files', () {
    test('get user files', () async {
      final riveApi = MockRiveApi();
      final me = getMe();
      final folder = getFolder(me);
      when(riveApi.get('/api/files/ids/${me.ownerId}/${folder.id}/recent'))
          .thenAnswer((_) async => successFilesResponse);
      final mockApi = FileApi(riveApi);

      final files = await mockApi.files(me.ownerId, folder.id);
      expect(files.length, 16);
      files.forEach((file) {
        expect(file.id, isNotNull);
        expect(file.ownerId, isNotNull);
        expect(file.name, isNull);
        expect(file.thumbnail, isNull);
      });
    });

    test('get user file details', () async {
      final riveApi = MockRiveApi();
      when(riveApi.post('/api/files/details', body: '[1,2,3]'))
          .thenAnswer((_) async => successFileDetailsResponse);
      final mockApi = FileApi(riveApi);
      final files = await mockApi.fileDetails([1, 2, 3]);
      expect(files.length, 3);
      files.forEach((file) {
        expect(file.id, isNotNull);
        expect(file.name, isNotNull);
        expect(file.ownerId, 1);
        expect(file.thumbnail, isNotNull);
      });
      expect(files.first.name, 'New File');
      expect(files.first.thumbnail, 'http://foofo.com/<thumbnail>?param');
      expect(files.last.name, 'New File 3');
      expect(files.last.thumbnail, 'http://foofo.com/<thumbnail3>?param');
    });

    test('get team files', () async {
      final riveApi = MockRiveApi();
      final team = getTeam();
      final folder = getFolder(team);
      when(riveApi.get('/api/files/ids/${team.ownerId}/${folder.id}/recent'))
          .thenAnswer((_) async => successFilesResponse);
      final mockApi = FileApi(riveApi);
      final files = await mockApi.files(
        folder.ownerId,
        folder.id,
      );
      expect(files.length, 16);
      files.forEach((file) {
        expect(file.id != null, true);
        expect(file.name, null);
        expect(file.ownerId, 3);
        expect(file.thumbnail, null);
      });
    });

    test('get team file details', () async {
      final riveApi = MockRiveApi();
      when(riveApi.post('/api/files/details', body: '[1,2,3]'))
          .thenAnswer((_) async => successFileDetailsResponse);
      final mockApi = FileApi(riveApi);
      final files = await mockApi.fileDetails([1, 2, 3]);
      expect(files.length, 3);
      files.forEach((file) {
        expect(file.id != null, true);
        expect(file.name != null, true);
        expect(file.ownerId, 1);
        expect(file.thumbnail != null, true);
      });
      expect(files.first.name, 'New File');
      expect(files.first.thumbnail, 'http://foofo.com/<thumbnail>?param');
      expect(files.last.name, 'New File 3');
      expect(files.last.thumbnail, 'http://foofo.com/<thumbnail3>?param');
    });

    test('get create user file', () async {
      final riveApi = MockRiveApi();
      when(riveApi.post('/api/files/1/create/1')).thenAnswer((_) async {
        return successFileCreationResponse;
      });
      final mockApi = FileApi(riveApi);
      final newFile = await mockApi.createFile(1, 1);
      expect(newFile.name, 'New File');
      expect(newFile.id, 10);
      expect(newFile.thumbnail, null);
      expect(newFile.ownerId, 1);
    });

    test('get create team file', () async {
      final riveApi = MockRiveApi();
      final team = getTeam();
      const folderId = 1;
      when(riveApi.post('/api/files/${team.ownerId}/create/$folderId'))
          .thenAnswer((_) async => successFileCreationResponse);
      final mockApi = FileApi(riveApi);

      final newFile = await mockApi.createFile(team.ownerId, folderId);
      expect(newFile.name, 'New File');
      expect(newFile.id, 10);
      expect(newFile.thumbnail, null);
      expect(newFile.ownerId, 1);
    });

    test('get user recent file ids', () async {
      final riveApi = MockRiveApi();
      when(riveApi.get('/api/files/ids/recent'))
          .thenAnswer((_) async => successRecentFilesResponse);
      final mockApi = FileApi(riveApi);
      final recentFiles = (await mockApi.recentFiles()).toList();
      expect(recentFiles.length, 3);
      expect(recentFiles[0].id, 1);
      expect(recentFiles[1].id, 2);
      expect(recentFiles[2].id, 4);
    });
  });

  group('Notifications', () {
    test('get notifications', () async {
      final riveApi = MockRiveApi();
      when(riveApi.get('/api/notifications'))
          .thenAnswer((_) async => successNotificationsResponse);
      final mockApi = NotificationsApi(riveApi);
      final notifications = await mockApi.notifications;
      expect(notifications.length, 2);
      expect(notifications.first is TeamInviteAcceptedNotificationDM, true);
      expect(notifications.last is TeamInviteRejectedNotificationDM, true);
    });

    test('get notification count', () async {
      final riveApi = MockRiveApi();
      when(riveApi.get('/api/notifications'))
          .thenAnswer((_) async => successNotificationsResponse);
      final mockApi = NotificationsApi(riveApi);
      final notificationCount = await mockApi.notificationCount;
      expect(notificationCount.count, 2);
    });
  });
}
