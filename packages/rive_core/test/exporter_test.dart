import 'package:flutter_test/flutter_test.dart';
import 'package:local_data/local_data.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/backboard.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/runtime/runtime_exporter.dart';
import 'package:rive_core/runtime/runtime_header.dart';
import 'package:rive_core/runtime/runtime_importer.dart';

void main() {
  RiveFile exportFrom;
  RiveFile importTo;
  Backboard backboard;
  Artboard artboard;

  setUpAll(() {
    LocalDataPlatform dataPlatform = LocalDataPlatform.make();

    exportFrom = RiveFile(
      'fake',
      localDataPlatform: dataPlatform,
    );
    importTo = RiveFile(
      'fake',
      localDataPlatform: dataPlatform,
    );

    // Make a somewhat sane file.
    exportFrom.batchAdd(() {
      backboard = Backboard();
      artboard = Artboard()
        ..name = 'My Artboard'
        ..x = 0
        ..y = 0
        ..width = 1920
        ..height = 1080;

      exportFrom.add(backboard);
      exportFrom.add(artboard);
    });
    exportFrom.captureJournalEntry();
    return exportFrom;
  });

  test('Export a Rive file', () {
    var exporter = RuntimeExporter(
      core: exportFrom,
      info: RuntimeHeader(ownerId: 1, fileId: 1),
    );
    var bytes = exporter.export();

    expect(bytes != null, true);
    expect(bytes.isNotEmpty, true);
  });

  test('Exported file is valid', () {
    var exporter = RuntimeExporter(
      core: exportFrom,
      info: RuntimeHeader(ownerId: 1, fileId: 1),
    );
    var bytes = exporter.export();

    var importer = RuntimeImporter(core: importTo);
    expect(importer.import(bytes), true);
    expect(importer.backboard != null, true);

    var artboards = importTo.objectsOfType<Artboard>();
    expect(artboards.length, 1);
    expect(artboards.first.name, 'My Artboard');
    expect(artboards.first.x, 0);
    expect(artboards.first.y, 0);
    expect(artboards.first.width, 1920);
    expect(artboards.first.height, 1080);
  });

  test('Exported contents parent properly', () {
    // Add some nodes.
    Node a, b, c, d;
    exportFrom.batchAdd(() {
      a = Node()..name = 'A';
      exportFrom.add(a);
      artboard.appendChild(a);

      b = Node()..name = 'B';
      exportFrom.add(b);
      a.appendChild(b);

      c = Node()..name = 'C';
      exportFrom.add(c);
      a.appendChild(c);

      d = Node()..name = 'D';
      exportFrom.add(d);
      b.appendChild(d);
    });

    var exporter = RuntimeExporter(
      core: exportFrom,
      info: RuntimeHeader(ownerId: 1, fileId: 1),
    );
    var bytes = exporter.export();

    var importer = RuntimeImporter(core: importTo);
    expect(importer.import(bytes), true);
    expect(importer.backboard != null, true);

    var artboards = importTo.objectsOfType<Artboard>();
    expect(artboards.length, 1);
    expect(artboards.first.name, 'My Artboard');
    expect(artboards.first.x, 0);
    expect(artboards.first.y, 0);
    expect(artboards.first.width, 1920);
    expect(artboards.first.height, 1080);

    expect(artboards.first.children.first.name, 'A');
    expect(artboards.first.children.first is Node, true);
    expect((artboards.first.children.first as Node).children.length, 2);
    expect((artboards.first.children.first as Node).children[1].name, 'C');
  });
}
