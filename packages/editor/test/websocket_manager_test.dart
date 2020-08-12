import 'dart:io';

import 'package:mockito/mockito.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/plumber.dart';
import 'package:rive_editor/rive/managers/notification_manager.dart';
import 'package:rive_editor/rive/managers/websocket_comms_manager.dart';
import 'package:test/test.dart';

import 'helpers/test_helpers.dart';
import 'helpers/test_models.dart';

class TestCommsWebsocketClient extends CommsWebsocketClient {
  @override
  final raiseErrors = true;

  @override
  Future<String> getUrl() async {
    return 'ws://127.0.0.1:7777';
  }

  @override
  Future<void> onConnect() async {}
}

class MockNotificationManager extends Mock implements NotificationManager {
  final host = '';
}

class DummyServer {
  var dataList = <dynamic>[];
  HttpServer _server;

  Future<bool> close() async {
    await _server.close(force: true);
    return true;
  }

  Future<bool> listen({int port}) async {
    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);

    _server.listen((HttpRequest request) async {
      // Attempt to upgrade the HTTP connection to a web socket
      var ws = await WebSocketTransformer.upgrade(request);
      ws.listen(
        (dynamic data) {
          dataList.add(data);
          if (data as String == 'killme') {
            ws.close();
          }
        },
        onDone: () {
          ws.close();
        },
        onError: (dynamic err) => ws.close(),
        cancelOnError: true,
      );
    });
  }
}

void main() {
  group('Websockets Coms Manager Tests', () {
    DummyServer server;
    WebsocketCommsManager manager;
    TestCommsWebsocketClient client;
    MockNotificationManager notificationsMananger;

    setUp(() async {
      server = DummyServer();
      client = TestCommsWebsocketClient();
      notificationsMananger = MockNotificationManager();
      manager = WebsocketCommsManager.tester(notificationsMananger, client);
      await server.listen(port: 7777);
    });
    tearDown(() async {
      await server.close();
      await manager?.dispose();
      Plumber().reset();
    });
    test('new notification message triggers notifications update', () async {
      verifyNever(notificationsMananger.update());
      await client.handleData('{"action": "NewNotification"}');
      verify(notificationsMananger.update()).called(1);
    });

    test('ping doenst blow up the mangager', () async {
      await client.handleData('{"action": "Ping"}');
    });
    test('random update blows up the manager', () async {
      expect(() => client.handleData('{"action": "Rambo"}'), throwsException);
    });

    test('updating folder with no currentdirectory does nothing', () async {
      final testComplete = testStream(
        Plumber().getStream<CurrentDirectory>(),
        <Function(CurrentDirectory)>[],
      );
      await client.handleData('''
{"action": "FolderChange", "params": {"folderOwnerId": 1, "folderId": 1}}''');
      await testComplete.future;
    });

    test('updating folder with different currentDirectory does nothing',
        () async {
      var team = getTeam();
      Plumber().message<CurrentDirectory>(
          CurrentDirectory(getTeam(), getFolder(team, 2)));

      final testComplete = testStream(
        Plumber().getStream<CurrentDirectory>(),
        [(CurrentDirectory d) => d.folder.id == 2],
      );
      await client.handleData('''
{"action": "FolderChange", "params":{"folderOwnerId": 1, "folderId": 1}}''');
      await client.handleData('''
{"action": "FolderChange", "params":{"folderOwnerId": 2, "folderId": 2}}''');
      await testComplete.future;
    });

    test(
        'updating folder with matching currentDirectory '
        'reloads the current directory', () async {
      var team = getTeam();
      Plumber().message<CurrentDirectory>(
          CurrentDirectory(getTeam(), getFolder(team, 1)));

      final testComplete = testStream(
        Plumber().getStream<CurrentDirectory>(),
        [
          (CurrentDirectory d) => d.folder.id == 1,
          (CurrentDirectory d) => d.folder.id == 1
        ],
      );
      await client.handleData('''
{"action": "FolderChange", "params":{"folderOwnerId": 1, "folderId": 1}}''');
      await testComplete.future;
    });
  });
}
