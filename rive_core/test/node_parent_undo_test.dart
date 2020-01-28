import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/rive_file.dart';

/// Some of the concepts in these tests are discussed in the Notion article
/// Hierarchy & Undo located here:
/// https://www.notion.so/Hierarchy-Undo-9781b750356943c49818d71d5c53562e
void main() {
  test('re-parent node', () {
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

    // except the artboard to have resolved properly
    expect(node1.artboard, artboard1);
    expect(node2.artboard, artboard1);

    expect(node1.parent, artboard1);
    expect(node1.parentId, artboard1.id);

    // move node to second artboard
    artboard2.addChild(node1);

    file.captureJournalEntry();

    // except the artboard to have resolved properly
    expect(node1.artboard, artboard2);

    // expect node2 to still be in artboard1
    expect(node2.artboard, artboard1);

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

    // expect both node's artboards to resolve to artboard1
    expect(node1.artboard, artboard1);
    expect(node2.artboard, artboard1);

    // expect fractional indexes to stay the same
    expect(node1.childOrder, const FractionalIndex(1, 2));
    expect(node2.childOrder, const FractionalIndex(2, 3));
  });

  /// This test re-parents a complex hierarchy by moving node a between e and f
  /// (under b).
  // ┌────────┐              ┌────────┐
  // │Artboard│      ->      │Artboard│
  // └────────┘              └────────┘
  //      ▲                       ▲
  //      │ ┌───┐                 │ ┌───┐
  //      ├─│ a │                 └─│ b │
  //      │ └───┘                   └───┘
  //      │   ▲                       ▲    ┌───┐
  //      │   │    ┌───┐              ├────│ e │
  //      │   ├────│ c │              │    └───┘
  //      │   │    └───┘              │
  //      │   │    ┌───┐              │
  //      │   └────│ d │              │    ┌───┐
  //      │        └───┘              ├────│ a │
  //      │ ┌───┐                     │    └───┘
  //      └─│ b │                     │      ▲
  //        └───┘                     │      │    ┌───┐
  //          ▲    ┌───┐              │      ├────│ c │
  //          ├────│ e │              │      │    └───┘
  //          │    └───┘              │      │    ┌───┐
  //          │    ┌───┐              │      └────│ d │
  //          └────│ f │              │           └───┘
  //               └───┘              │
  //                                  │    ┌───┐
  //                                  └────│ f │
  //                                       └───┘
  test('re-parent complex', () {
    final file = RiveFile("fake");

    var artboard = file.add(Artboard()..name = 'Artboard');
    // Create the node with some name set to it.
    var a = file.add(Node()..name = 'a');
    var b = file.add(Node()..name = 'b');
    var c = file.add(Node()..name = 'c');
    var d = file.add(Node()..name = 'd');
    var e = file.add(Node()..name = 'e');
    var f = file.add(Node()..name = 'f');

    a.addChild(c);
    a.addChild(d);

    b.addChild(e);
    b.addChild(f);

    artboard.addChild(a);
    artboard.addChild(b);

    file.captureJournalEntry();

    // Expect structure to match diagram above
    expect(a.parent, artboard);
    expect(c.parent, a);
    expect(d.parent, a);
    expect(b.parent, artboard);
    expect(e.parent, b);
    expect(f.parent, b);

    expect(a.childOrder, const FractionalIndex(1, 2));
    expect(c.childOrder, const FractionalIndex(1, 2));
    expect(d.childOrder, const FractionalIndex(2, 3));
    expect(b.childOrder, const FractionalIndex(2, 3));
    expect(e.childOrder, const FractionalIndex(1, 2));
    expect(f.childOrder, const FractionalIndex(2, 3));

    // Move a under b between e and f
    b.addChild(a, updateIndex: false);
    b.children.move(a, after: e, before:f);

    file.captureJournalEntry();

    // Expect structure to match the second diagram above
    expect(a.parent, b);
    expect(c.parent, a);
    expect(d.parent, a);
    expect(b.parent, artboard);
    expect(e.parent, b);
    expect(f.parent, b);

    expect(a.childOrder, const FractionalIndex(3, 5));
    expect(c.childOrder, const FractionalIndex(1, 2));
    expect(d.childOrder, const FractionalIndex(2, 3));
    expect(b.childOrder, const FractionalIndex(2, 3));
    expect(e.childOrder, const FractionalIndex(1, 2));
    expect(f.childOrder, const FractionalIndex(2, 3));

    file.undo();

    // Expect structure to match diagram above
    expect(a.parent, artboard);
    expect(c.parent, a);
    expect(d.parent, a);
    expect(b.parent, artboard);
    expect(e.parent, b);
    expect(f.parent, b);

    expect(a.childOrder, const FractionalIndex(1, 2));
    expect(c.childOrder, const FractionalIndex(1, 2));
    expect(d.childOrder, const FractionalIndex(2, 3));
    expect(b.childOrder, const FractionalIndex(2, 3));
    expect(e.childOrder, const FractionalIndex(1, 2));
    expect(f.childOrder, const FractionalIndex(2, 3));
  });
}
