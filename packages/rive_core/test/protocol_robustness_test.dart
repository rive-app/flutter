import 'dart:io';

import 'package:core/coop/connect_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_data/local_data.dart';
import 'package:rive_core/node.dart';
import 'package:pedantic/pedantic.dart';

import 'src/test_private_api.dart';
import 'src/test_rive_file.dart';
import 'src/test_server.dart';

const String filePath = '1203/3203/1203';

const int coopPort = 8124;
const int privateApiPort = 3003;

/// The purpose of these tests is to maintin the robustness of the coop
/// protocol.
void main() {
  test(
    'connecting to server',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();

      final server = TestCoopServer();
      expect(await server.listen(port: coopPort), true);

      LocalDataPlatform dataPlatform = LocalDataPlatform.make();

      // Connect client1
      final client1 = TestRiveFile(
        'fake',
        localDataPlatform: dataPlatform,
        overridePreferences: <String, dynamic>{
          'token': 'fake',
          'clientId': 1,
        },
        useSharedPreferences: false,
      );

      expect(
          await client1.connect('ws://localhost:$coopPort', filePath, 'fake'),
          ConnectResult.networkError,
          reason: 'expect network error when no private api is available');

      // Ok now let's make a private api for the coop server to talk to.
      final privateApi = TestPrivateApi();
      expect(await privateApi.listen(privateApiPort), true,
          reason: 'private api starts listening');

      unawaited(privateApi.startServing());

      expect(
        await client1.connect('ws://localhost:$coopPort', filePath, 'fake'),
        ConnectResult.connected,
      );

      // Wait for the first connection to settle (perform any initialization
      // changes that could've been queued up during connect).
      await client1.settle();
      print("Client1 settled");

      // make sure server has one connected client and file.
      expect(server.editingFileCount, 1,
          reason: "Server should have one editing file.");
      expect(server.clientCount, 1,
          reason: "Server should have one client connected.");

      var serverFileContext = server.isolates.first as TestCoopIsolate;

      // Connect client1
      final client2 = TestRiveFile(
        'fake',
        localDataPlatform: dataPlatform,
        overridePreferences: <String, dynamic>{
          'token': 'fake',
          'clientId': 2,
        },
        useSharedPreferences: false,
      );

      expect(
        await client2.connect('ws://localhost:$coopPort', filePath, 'fake'),
        ConnectResult.connected,
      );

      // Wait for the second connection to settle (perform any initialization
      // changes that could've been queued up during connect).
      await client2.settle();
      print("Client2 settled");

      // make sure server has one connected client and file.
      expect(server.editingFileCount, 1,
          reason: "Server should have one editing file.");
      expect(server.clientCount, 2,
          reason: "Server should have two clients connected.");

      // Put server in manual drive so we can advance commands manually and
      // deterministically.
      serverFileContext.manualDrive = true;

      var node = client1.add(Node()..name = 'nice-node');

      // Make the change and send them to the server.
      var changes = client1.captureTestChanges();

      print("Ok $changes, wait for command");

      // Wait for the server to receive the changes from the client.
      dynamic command = await serverFileContext.processNextCommand();
      print("COMMAND $command");

      // The changes should've been accepted by the server.
      expect(await changes.accept(), true);

      // node.name = 'name change2';
      // file.captureJournalEntry();
      // // // Give opportunity to save...
      // await Future.delayed(const Duration(milliseconds: 500), () {});
      // expect(await file.disconnect(), true);

      // // // give server opportunity to catch up...
      // await Future.delayed(CoopIsolate.killTimeout, () {});
      // await Future.delayed(const Duration(milliseconds: 100), () {});

      // expect(server.editingFileCount, 0,
      //     reason: "Editing file count should be 0");
      // expect(server.clientCount, 0);
      expect(await server.close(), true);
    },
    timeout: const Timeout(
      Duration(seconds: 15),
    ),
  );
}
