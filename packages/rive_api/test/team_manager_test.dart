import 'dart:async';

import 'package:mockito/mockito.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rive_api/src/api/api.dart';
import 'package:rive_api/src/model/model.dart';
import 'package:rive_api/src/manager/manager.dart';
import 'package:rive_api/src/plumber.dart';

import 'fixtures/api_responses.dart';
import 'fixtures/data_models.dart';
import 'helpers/test_helpers.dart';

class MockRiveApi extends Mock implements RiveApi {
  final host = '';
}

void main() {
  group('Team Manager ', () {
    MockRiveApi riveApi;
    TeamApi mockedTeamApi;
    TeamManager teamManager;
    setUp(() {
      riveApi = MockRiveApi();
      when(riveApi.getFromPath('/api/teams'))
          .thenAnswer((_) async => successTeamsResponse);
      when(riveApi.getFromPath('/api/teams/41545/affiliates'))
          .thenAnswer((_) async => successTeamMembersResponse);
      when(riveApi.getFromPath('/api/teams/41576/affiliates'))
          .thenAnswer((_) async => successTeamMembersResponse);

      mockedTeamApi = TeamApi(riveApi);
      teamManager = TeamManager.tester(mockedTeamApi);
    });
    tearDown(() {
      Plumber().reset();
    });

    test('load teams', () async {
      final testComplete = Completer();

      Plumber().getStream<List<Team>>().listen((teams) {
        expect(teams.length, 2);
        testComplete.complete();
      });

      teamManager.loadTeams();

      await testComplete.future;
    });

    test('load teams on new login', () async {
      final testComplete = Completer();

      Plumber().getStream<List<Team>>().listen((teams) {
        testComplete.complete();
      });

      Plumber().message(Me.fromDM(getMe()));

      await testComplete.future;
    });

    test('sequence', () async {
      final testComplete = testStream(
        Plumber().getStream<List<Team>>(),
        [
          (List<Team> teams) => teams?.length == 2,
          (List<Team> teams) => teams == null,
          (List<Team> teams) => teams?.length == 2,
          (List<Team> teams) => teams?.length == 2,
        ],
      );

      Plumber().message(Me.fromDM(getMe()));
      Plumber().message<Me>(Me.fromDM(null)); // Empty 'Me'.
      Plumber().message(Me.fromDM(getMe()));
      Plumber().message(Me.fromDM(getMe()));

      await testComplete.future;
    });

    test('current directory', () async {
      final testComplete = testStream(
        Plumber().getStream<CurrentDirectory>(),
        [
          (CurrentDirectory currentDirectory) =>
              currentDirectory.owner.ownerId == 41545,
          (CurrentDirectory currentDirectory) =>
              currentDirectory.owner.ownerId == 41545,
          (CurrentDirectory currentDirectory) =>
              currentDirectory.owner.ownerId == 999,
          (CurrentDirectory currentDirectory) =>
              currentDirectory.owner.ownerId == 41545,
          (CurrentDirectory currentDirectory) =>
              currentDirectory.owner.ownerId == 41545,
        ],
      );

      var teamInTeamsList = Team.fromDM(getTeam(ownerId: 41545));
      var teamOutsideTeamsList = Team.fromDM(getTeam(ownerId: 999));
      // Triggers event
      Plumber().message(getCurrentDirectory(teamInTeamsList));
      await Future<dynamic>.delayed(const Duration(milliseconds: 10));

      // Triggers event, as current dir in teamlist
      await teamManager.loadTeams();
      await Future<dynamic>.delayed(const Duration(milliseconds: 10));

      // Triggers event
      Plumber().message(getCurrentDirectory(teamOutsideTeamsList));
      await Future<dynamic>.delayed(const Duration(milliseconds: 10));

      // Doesnt trigger event, current dir not in teams list
      await teamManager.loadTeams();
      await Future<dynamic>.delayed(const Duration(milliseconds: 10));

      // Triggers event
      Plumber().message(getCurrentDirectory(teamInTeamsList));
      await Future<dynamic>.delayed(const Duration(milliseconds: 10));

      // Triggers event, as current dir in teamlist
      await teamManager.loadTeams();

      await testComplete.future;
    });
  });
}
