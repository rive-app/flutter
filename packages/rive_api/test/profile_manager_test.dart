import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/plumber.dart';

import 'fixtures/api_responses.dart';

class MockRiveApi extends Mock implements RiveApi {
  @override
  final host = '';
}

void main() {
  group('Profile Manager ', () {
    MockRiveApi riveApi;
    MeApi mockedMeApi;
    TeamApi mockedTeamApi;
    ProfileManager profileManager;
    Owner mockOwner;
    const failProfile = Profile(username: 'username with spaces');

    setUp(() {
      riveApi = MockRiveApi();
      when(
        riveApi.get('/api/profile'),
      ).thenAnswer((_) async => successProfileMeResponse);

      when(
        riveApi.put('/api/profile', body: failProfile.encoded),
      ).thenAnswer(
        (_) async => throw ApiException(errorUpdateProfileMeResponse),
      );
      mockedMeApi = MeApi(riveApi);
      mockedTeamApi = TeamApi(riveApi);
      profileManager = ProfileManager.tester(mockedMeApi, mockedTeamApi);
    });
    tearDown(() {
      Plumber().reset();
    });

    test('load my profile', () async {
      final testComplete = Completer<void>();
      mockOwner = const User(
        ownerId: 123,
        // missing fields: ignore.
      );

      Plumber().getStream<Profile>(mockOwner.ownerId).listen((profile) {
        expect(profile.username, 'mrfawlty');
        testComplete.complete();
      });

      await profileManager.loadProfile(mockOwner);

      await testComplete.future;
    });

    test('Wrong update characters', () async {
      final testComplete = Completer<void>();
      mockOwner = const User(
        // missing fields: ignore.
        ownerId: 123,
      );

      bool success = await profileManager.updateProfile(mockOwner, failProfile);

      expect(success, false);
      testComplete.complete();

      await testComplete.future;
    });
  });
}
