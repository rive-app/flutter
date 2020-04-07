import 'package:core/coop/connect_result.dart';
import 'package:core/coop/coop_isolate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_data/local_data.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/backboard.dart';
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

      // Make a somewhat sane file.
      Artboard artboardOnClient1;
      client1.batchAdd(() {
        var backboard = Backboard();
        artboardOnClient1 = Artboard()
          ..name = 'My Artboard'
          ..width = 1920
          ..height = 1080;

        client1.add(backboard);
        client1.add(artboardOnClient1);
      });
      client1.captureJournalEntry();

      // Wait for the first connection to settle (perform any initialization
      // changes that could've been queued up during connect).
      await client1.settle();

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

      // make sure server has one connected client and file.
      expect(server.editingFileCount, 1,
          reason: "Server should have one editing file.");
      expect(server.clientCount, 2,
          reason: "Server should have two clients connected.");

      // Put server in manual drive so we can advance commands manually and
      // deterministically.
      serverFileContext.manualDrive = true;

      // Make a node on client 1.
      var niceNodeOnClient1 = client1.add(Node()..name = 'nice-node');
      artboardOnClient1.appendChild(niceNodeOnClient1);

      // Make the change and send them to the server.
      var changes = client1.captureTestChanges();

      // Have client2 wait to receive the changes.
      var changesReceived = client2.waitForNextChanges();

      // Wait for the server to receive the changes from the client.
      await serverFileContext.processNextChange();

      // The changes should've been accepted by the server.
      expect(await changes.accept(), true);

      // The second client should've received the changes and now have
      // 'nice-node'.
      await changesReceived.future;

      var niceNodeOnClient2 = client2.resolve<Node>(niceNodeOnClient1.id);
      expect(niceNodeOnClient2 != null, true);
      expect(niceNodeOnClient2.name, 'nice-node');

      // Both clients attempt to change the same property.
      {
        niceNodeOnClient1.x = 10;
        niceNodeOnClient2.x = 20;

        var client2ChangesReceived = client2.waitForNextChanges();

        // Have client1 send the changes first.
        var client1Changes = client1.captureTestChanges();
        var client2Changes = client2.captureTestChanges();

        // Server processes one change.
        await serverFileContext.processNextChange();

        expect(await client1Changes.accept(), true);
        await client2ChangesReceived.future;

        // Changes received by both clients, expect client 1 to have niceNode at
        // 10 x and client 2 to still have it at 20 x because it has inflight
        // changes to that same property.
        expect(niceNodeOnClient1.x, 10);

        expect(
            client2.hasInflightChanges(
                niceNodeOnClient2.id, NodeBase.xPropertyKey),
            true);
        expect(niceNodeOnClient2.x, 20);

        // They should both settle at 20 right after the server accepts the next
        // changes.
        var client1ChangesReceived = client1.waitForNextChanges();

        // Server processes next change, which should be the change client2 made
        // to niceNode's x.
        await serverFileContext.processNextChange();

        expect(await client2Changes.accept(), true);
        // Expect no more inflight changes
        expect(
            client2.hasInflightChanges(
                niceNodeOnClient2.id, NodeBase.xPropertyKey),
            false);

        await client1ChangesReceived.future;

        // Changes have been accepted by client 2 and client 1 has received them
        // too.

        expect(niceNodeOnClient1.x, 20);
        expect(niceNodeOnClient2.x, 20);
      }

      // Undo
      {
        // If client 2 undoes the last change x goes from 20 => 0
        client2.undo();
        var client1ChangesReceived = client1.waitForNextChanges();

        // Process the change (undo) on the server.
        await serverFileContext.processNextChange();

        await client1ChangesReceived.future;

        // Both are back at 0
        expect(niceNodeOnClient1.x, 0);
        expect(niceNodeOnClient2.x, 0);
      }

      // Cyclic dependency.
      {
        Node nodeBOnClient1;
        Node nodeCOnClient1;
        client1.batchAdd(() {
          nodeBOnClient1 = client1.add(Node()..name = 'B');
          nodeCOnClient1 = client1.add(Node()..name = 'C');
          niceNodeOnClient1.appendChild(nodeBOnClient1);
          niceNodeOnClient1.appendChild(nodeCOnClient1);
        });

        var client2ChangesReceived = client2.waitForNextChanges();

        // Have client1 send the changes first.
        var client1Changes = client1.captureTestChanges();

        // Server processes one change.
        await serverFileContext.processNextChange();

        expect(await client1Changes.accept(), true);
        await client2ChangesReceived.future;

        // Ok we should now be synced with two new nodes in both client1 and 2.

        var nodeBOnClient2 = client2.resolve<Node>(nodeBOnClient1.id);
        var nodeCOnClient2 = client2.resolve<Node>(nodeCOnClient1.id);

        expect(nodeBOnClient2 != null, true);
        expect(nodeBOnClient2.name, 'B');

        expect(nodeCOnClient2 != null, true);
        expect(nodeCOnClient2.name, 'C');

        // Ok now everyone's in sync.
        {
          // Client 2 puts B under C.
          nodeCOnClient2.appendChild(nodeBOnClient2);

          // Client 1 puts C under B.
          nodeBOnClient1.appendChild(nodeCOnClient1);

          // Have client 2 send changes first.
          var client2Changes = client2.captureTestChanges();
          var client1Changes = client1.captureTestChanges();

          // Server processes client2's changes.
          await serverFileContext.processNextChange();

          expect(await client2Changes.accept(), true);

          // Server processes client1's changes.
          await serverFileContext.processNextChange();

          // Second changes should get denied as they result in a cyclic
          // dependency on the server (clients actually don't see this cycle as
          // they just place B and C as child/parents of each other and
          // effectively disappear from the hierarchy). That's ok, server
          // rejects the change and the client that's in a bad state reconnects
          // as its changes are rejected.
          expect(await client1Changes.accept(), false);

          // Since changes were denied, we expect the client to disconnect.
          expect(
              await serverFileContext.processNextCommand()
                  is CoopServerRemoveClient,
              true);

          // ... and then immediately reconnect.
          expect(
              await serverFileContext.processNextCommand()
                  is CoopServerAddClient,
              true);

        }
      }

      // put server back in auto
      serverFileContext.manualDrive = false;

      expect(await client1.disconnect(), true);
      expect(await client2.disconnect(), true);

      await Future.delayed(CoopIsolate.killTimeout, () {});
      await Future.delayed(const Duration(milliseconds: 1000), () {});

      expect(server.editingFileCount, 0,
          reason: "Editing file count should be 0");

      expect(await server.close(), true);
    },
    timeout: const Timeout(
      Duration(seconds: 15),
    ),
  );
}
