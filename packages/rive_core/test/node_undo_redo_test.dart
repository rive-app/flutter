import 'package:flutter_test/flutter_test.dart';
import 'package:local_data/local_data.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/backboard.dart';
import 'package:rive_core/node.dart';

import 'src/test_rive_file.dart';

void main() {
  test('undo/redo node name', () {
    LocalDataPlatform dataPlatform = LocalDataPlatform.make();

    final file = TestRiveFile(
      'fake',
      localDataPlatform: dataPlatform,
      overridePreferences: <String, dynamic>{
        'token': 'fake',
        'clientId': 1,
      },
      useSharedPreferences: false,
    );

    const String name1 = 'First Name';
    const String name2 = 'Second Name';
    const String name3 = 'Third Name';

    // Objects need to be owned by an artboard, so let's make one.
    Artboard artboard;
    Node node;
    file.batchAdd(() {
      var backboard = Backboard();
      artboard = Artboard()
        ..name = 'My Artboard'
        ..width = 1920
        ..height = 1080;

      file.add(backboard);
      file.add(artboard);
      
      // Create the node with some name set to it.
      node = file.add(Node()..name = name1);
      artboard.appendChild(node);
    });
    // capture an entry for the creation of the object.
    file.captureJournalEntry();

    // Change the name.
    node.name = name2;
    // Capture a change (usually happens when an operation completes, like the
    // user releases the mouse or presses enter on an input field).
    file.captureJournalEntry();

    // Expect there to be two changes in the journal.
    expect(file.journal.length, 2);

    // Expect the name to be what we changed it to.
    expect(node.name, name2);
    // Expect the undo operation to succeed.
    expect(file.undo(), true);
    // Expect the name to have been changed back to name1.
    expect(node.name, name1);
    // Expect there to still be two changes in the journal.
    expect(file.journal.length, 2);

    // Expect the redo operation to succeed.
    expect(file.redo(), true);
    // Expect the name to have changed back to name2.
    expect(node.name, name2);
    // Expect there to still be two changes in the journal.
    expect(file.journal.length, 2);
    // Expect undo to succeed.
    expect(file.undo(), true);
    // Expect name to have changed back to name1.
    expect(node.name, name1);

    // Change name to name3 and capture another journal entry.
    node.name = name3;
    file.captureJournalEntry();

    // Exepect redo to fail as changing from name1 to name3 should've removed
    // name2 from the change stack.
    expect(file.redo(), false);

    // Remove node from the file.
    file.remove(node);

    // Expect it to no longer be held/referenced by the file.
    expect(file.isHolding(node), false);
  });
}
