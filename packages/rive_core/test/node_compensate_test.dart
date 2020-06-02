import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:local_data/local_data.dart';

import 'package:rive_core/artboard.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/rive_file.dart';

/// Some of the concepts in these tests are discussed in the Notion article
/// Hierarchy & Undo located here:
/// https://www.notion.so/Hierarchy-Undo-9781b750356943c49818d71d5c53562e
void main() {
  test('compensate node world transform', () {
    LocalDataPlatform dataPlatform = LocalDataPlatform.make();
    final file = RiveFile('fake', localDataPlatform: dataPlatform);

    Artboard artboard1;
    Node node1, node2;
    file.batchAdd(() {
      // Create the node with some name set to it.
      node1 = file.addObject(Node()..name = 'Node 1')
        ..x = 221
        ..y = 59
        ..rotation = 27.133 / 180 * pi
        ..scaleX = 2
        ..scaleY = 2;
      node2 = file.addObject(Node()..name = 'Node 2')
        ..x = 336
        ..y = 141;

      artboard1 = file.addObject(Artboard()..name = 'Artboard A')
        ..width = 100
        ..height = 100
        ..appendChild(node1)
        ..appendChild(node2);
    });

    file.captureJournalEntry();

    // Run the update cycle.
    artboard1.advance(0);

    // Reparent and advance to update world transforms.
    node2.parent = node1;
    file.captureJournalEntry();
    artboard1.advance(0);

    expect(node2.worldTransform[4] != 336, true);
    expect(node2.worldTransform[5] != 141, true);

    file.undo();
    artboard1.advance(0);

    expect(node2.worldTransform[4], 336);
    expect(node2.worldTransform[5], 141);
    expect(node2.parent, artboard1);

    // This time re-parent with compensation...
    node2.parent = node1;
    // Make sure compensate is called before advance and capture...
    node2.compensate();
    file.captureJournalEntry();
    artboard1.advance(0);

    expect(node2.worldTransform[4], 336);
    expect(node2.worldTransform[5], 141);
  });
}
