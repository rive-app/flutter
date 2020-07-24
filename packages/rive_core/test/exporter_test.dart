import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_data/local_data.dart';
import 'package:rive_core/animation/keyframe_double.dart';
import 'package:rive_core/animation/linear_animation.dart';
import 'package:rive_core/animation/loop.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/backboard.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/runtime/runtime_exporter.dart';
import 'package:rive_core/runtime/runtime_header.dart';
import 'package:rive_core/runtime/runtime_importer.dart';
import 'package:rive_core/shapes/paint/fill.dart';
import 'package:rive_core/shapes/paint/solid_color.dart';
import 'package:rive_core/shapes/rectangle.dart';
import 'package:rive_core/shapes/shape.dart';

void main() {
  RiveFile exportFrom;
  RiveFile importTo;
  Backboard backboard;
  Artboard artboard;

  setUp(() {
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

      exportFrom.addObject(backboard);
      exportFrom.addObject(artboard);

      // Add solid color fill to artboard.
      var solidColor = SolidColor()..colorValue = 0xFF313131;
      var fill = Fill()..name = 'Background';
      exportFrom.addObject(fill);
      exportFrom.addObject(solidColor);
      artboard.appendChild(fill);
      fill.appendChild(solidColor);
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
      exportFrom.addObject(a);
      artboard.appendChild(a);

      b = Node()..name = 'B';
      exportFrom.addObject(b);
      a.appendChild(b);

      c = Node()..name = 'C';
      exportFrom.addObject(c);
      a.appendChild(c);

      d = Node()..name = 'D';
      exportFrom.addObject(d);
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

    expect(artboards.first.children[1].name, 'A');
    expect(artboards.first.children[1] is Node, true);
    expect((artboards.first.children[1] as Node).children.length, 2);
    expect((artboards.first.children[1] as Node).children[1].name, 'C');
  });

  test('Can generate a simple animated file', () {
    // Add some nodes.
    Node a;
    Shape shape;
    Rectangle path;
    exportFrom.batchAdd(() {
      a = Node()
        ..name = 'A'
        ..x = 960
        ..y = 540;
      exportFrom.addObject(a);
      artboard.appendChild(a);

      shape = Shape()
        ..name = 'Rectangle Shape'
        ..x = 0
        ..y = 0;
      exportFrom.addObject(shape);
      a.appendChild(shape);

      path = Rectangle()
        ..name = 'Rectangle Path'
        ..x = 0
        ..y = 0
        ..width = 256
        ..height = 256;
      exportFrom.addObject(path);
      shape.appendChild(path);

      const fillColor = Color(0xFF00FF00);
      shape.createFill(fillColor);

      // Make the rectangle spin (let's just animate the node that contains it).
      var animation = LinearAnimation()
        ..name = 'Spin'
        ..fps = 60
        ..loop = Loop.pingPong
        ..artboardId = artboard.id;
      exportFrom.addObject(animation);

      var keyedObject = animation.makeKeyed(a);

      // Start keying rotation
      keyedObject.makeKeyed(NodeBase.rotationPropertyKey);

      // Add keyframe at 0 frames with value of 0
      a
          .addKeyFrame<KeyFrameDouble>(
              animation, NodeBase.rotationPropertyKey, 0)
          .value = 0;
      // Add keyframe at 60 frames (1 second) with value of 2 pi (360)
      a
          .addKeyFrame<KeyFrameDouble>(
              animation, NodeBase.rotationPropertyKey, 60)
          .value = 2 * pi;

      exportFrom.captureJournalEntry();
    });

    var exporter = RuntimeExporter(
      core: exportFrom,
      info: RuntimeHeader(ownerId: 1, fileId: 1),
    );
    var bytes = exporter.export();

    const filePath = './rectangle.riv';
    var file = File(filePath);
    file.create(recursive: true);
    file.writeAsBytesSync(bytes, flush: true);

    assert(
      FileSystemEntity.typeSync(filePath) != FileSystemEntityType.notFound,
    );

    file.delete();
  });
}
