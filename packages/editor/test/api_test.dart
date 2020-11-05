// ignore_for_file: sdk_version_async_exported_from_core
// ignore_for_file: unawaited_futures

import 'dart:convert';

import 'package:mockito/mockito.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/auth.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;

// Create a MockClient using the Mock class provided by the Mockito package.
// Create new instances of this class in each test.
class RiveTestApi extends Mock implements RiveApi {
  @override
  String get host => 'https://arkham.rive.app';
}

// class EditorRiveFilesTestApi extends Mock
//     implements RiveFilesApi<RiveFolder, RiveFile> {
//   FileBrowser get browser => _fileBrowser;
//   final _fileBrowser = FileBrowser(null);

//   @override
//   RiveApi get api => RiveTestApi();

//   @override
//   RiveFile makeFile(int id, {String name, int ownerId}) {
//     return RiveFile(id, browser, name: name, ownerId: ownerId);
//   }

//   @override
//   RiveFolder makeFolder(Map<String, dynamic> data) {
//     return RiveFolder(data);
//   }
// }

void main() {
  group('Check RiveApi', () {
    test('initialize() returns true', () async {
      final client = RiveTestApi();

      when(client.initialize()).thenAnswer((_) async => true);

      expect(await client.initialize(), true);
    });

    test('Check http get', () async {
      final client = RiveTestApi();

      when(client.get('https://arkham.rive.app'))
          .thenAnswer((_) async => http.Response('{"test": ""}', 200));

      final _response = (await client.get('https://arkham.rive.app')).body;
      expect(_response, '{"test": ""}');
    });
  });

  group('Check RiveAuth', () {
    test('Auth login returns true', () async {
      final client = RiveTestApi();
      final auth = RiveAuth(client);

      when(auth.api.post(client.host + '/signin',
              body: jsonEncode(
                <String, String>{
                  'username': 'rive_user',
                  'password': '123456789',
                },
              )))
          .thenAnswer((_) async => http.Response('{"username": "test"}', 200));
      final authResponse = await auth.login('rive_user', '123456789');
      expect(authResponse.message, "test");
    });
  });
}
