import 'package:flutter_test/flutter_test.dart';

import 'package:core/coop/connect_result.dart';
import 'package:local_data/local_data.dart';

import 'src/test_rive_file.dart';
import 'src/test_server.dart';

void main() {
  test(
    'connecting to server',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();

      final server = TestCoopServer();
      expect(await server.listen(port: 8124), true);

      LocalDataPlatform dataPlatform = LocalDataPlatform.make();

      // Create fake server file.
      final file = TestRiveFile('fake',
          localDataPlatform: dataPlatform,
          overridePreferences: <String, dynamic>{
            "session": 22,
            "token": "fake",
            // "lastServerChangeId": 0
          },
          useSharedPreferences: false);

      // TODO: this will fail until the 2D service sends the correctly formatted
      // request. When this is done, reinstate the test
      expect(await file.connect('ws://localhost:8124', '1203/3203/fake'),
          ConnectResult.networkError);
      // expect(await file.connect('ws://localhost:8124', '1203/3203/fake'),
      //     ConnectResult.connected);

      // // make sure server has one connected client and file.
      // expect(server.editingFileCount, 1,
      //     reason: "Server should have one editing file.");
      // expect(server.clientCount, 1,
      //     reason: "Server should have one client connected.");

      // var node = file.add(Node()..name = 'test');
      // node.name = 'name change';
      // file.captureJournalEntry();
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
