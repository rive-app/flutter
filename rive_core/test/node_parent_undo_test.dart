import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/rive_file.dart';

void main() {
  test('reparent node', () {
    final file = RiveFile("fake");

    // Create the node with some name set to it.
    var node1 = file.add(Node()..name = 'Node 1');
    var node2 = file.add(Node()..name = 'Node 2');

    var artboard1 = file.add(Artboard()..name = 'Artboard A')
      ..addChild(node1)
      ..addChild(node2);

    // Expect node1 to be at 1/2 and node2 at 2/3
    expect(node1.childOrder, const FractionalIndex(1, 2));
    expect(node2.childOrder, const FractionalIndex(2, 3));

    var artboard2 = file.add(Artboard()..name = 'Artboard B');

    // capture an entry for the default state.
    file.captureJournalEntry();

    expect(node1.parent, artboard1);
    expect(node1.parentId, artboard1.id);

    // move node to second artboard
    artboard2.addChild(node1);

    file.captureJournalEntry();

    // expect node to be in the second artboard
    expect(node1.parent, artboard2);
    expect(node1.parentId, artboard2.id);

    // expect fractional indexes to stay the same
    expect(node1.childOrder, const FractionalIndex(1, 2));
    expect(node2.childOrder, const FractionalIndex(2, 3));

    // undo, the node should be back in the first artboard
    file.undo();

    // expect node1 to be back in artboard1
    expect(node1.parentId, artboard1.id);
    expect(node1.parent, artboard1);

    // expect fractional indexes to stay the same
    expect(node1.childOrder, const FractionalIndex(1, 2));
    expect(node2.childOrder, const FractionalIndex(2, 3));
    
    print("node1 ${node1.childOrder}");
  });
}
