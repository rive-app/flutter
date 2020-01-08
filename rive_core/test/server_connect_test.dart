import 'package:core/coop/connect_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/rive_file.dart';
import 'package:core/coop/coop_isolate.dart';

import 'src/test_server.dart';

void main() {
  test('connecting to server', () async {
    TestWidgetsFlutterBinding.ensureInitialized();

    final server = TestCoopServer();
    expect(await server.listen(port: 8124), true);
    // Create fake server file.
    final file = RiveFile("fake",
        overridePreferences: <String, dynamic>{
          "session": 22,
          "token": "fake",
          // "lastServerChangeId": 0
        },
        useSharedPreferences: false);
    expect(await file.connect('ws://localhost:8124/1203/3203'),
        ConnectResult.connected);

    // make sure server has one connected client and file.
    expect(server.editingFileCount, 1,
        reason: "Server should have one editing file.");
    expect(server.clientCount, 1,
        reason: "Server should have one client connected.");

    print('connected');
    var node = file.add(Node()..name = 'test');
    node.name = 'name change';
    file.captureJournalEntry();
    node.name = 'name change2';
    file.captureJournalEntry();
    // Give opportunity to save...
    await Future.delayed(const Duration(milliseconds: 1000), () {});

    print("disconnect");
    expect(await file.disconnect(), true);
    print("Waiting for isolate shutdown...");
    // give server opportunity to catch up...
    await Future.delayed(CoopIsolate.killTimeout, () {});
    await Future.delayed(const Duration(milliseconds: 100), () {});

    expect(server.editingFileCount, 0,
        reason: "Editing file count should be 0");
    expect(server.clientCount, 0);
    expect(await server.close(), true);

    print('done');
  });
}
