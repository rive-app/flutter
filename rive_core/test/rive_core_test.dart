import 'package:flutter_test/flutter_test.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/rive_file.dart';

void main() {
  test('connecting to server', () async {
    final file = RiveFile();
    expect(await file.connect(), true);

    print('connected');
    var node = file.add(Node()..name = 'test');
    node.name = 'name change';
    file.captureJournalEntry();
    await Future.delayed(const Duration(seconds: 10), () {});
    print('done');
  });
  test('undo/redo node name', () {
    final file = RiveFile();

    const String name1 = 'First Name';
    const String name2 = 'Second Name';
    const String name3 = 'Third Name';

    // Create the node with some name set to it.
    var node = file.add(Node()..name = name1);

    // Change the name.
    node.name = name2;
    // Capture a change (usually happens when an operation completes, like the
    // user releases the mouse or presses enter on an input field).
    file.captureJournalEntry();

    // Expect there to be one change in the journal.
    expect(file.journal.length, 1);

    // Expect the name to be what we changed it to.
    expect(node.name, name2);
    // Expect the undo operation to succeed.
    expect(file.undo(), true);
    // Expect the name to have been changed back to name1.
    expect(node.name, name1);
    // Expect the undo to fail as the journal is now empty.
    expect(file.undo(), false);
    // Expect the redo operation to succeed.
    expect(file.redo(), true);
    // Execpt the name to have changed back to name2.
    expect(node.name, name2);
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
