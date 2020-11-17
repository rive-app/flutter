import 'dart:io';

import 'package:flutter_svg/src/svg/parser_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peon_process/src/helpers/convert_svg.dart';
import 'package:peon_process/src/helpers/flare_to_rive.dart';
import 'package:peon_process/src/helpers/svg_utils/paths.dart';
import 'package:peon_process/src/tasks/svg_to_rive.dart';
import 'package:rive_core/bones/bone.dart';
import 'package:rive_core/bones/root_bone.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/runtime/runtime_exporter.dart';
import 'package:rive_core/runtime/runtime_header.dart';
import 'package:rive_core/shapes/clipping_shape.dart';
import 'package:rive_core/shapes/paint/fill.dart';
import 'package:rive_core/shapes/paint/linear_gradient.dart';
import 'package:rive_core/shapes/paint/radial_gradient.dart';
import 'package:rive_core/shapes/paint/stroke.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:xml/xml_events.dart' as xml show parseEvents;

import 'fixtures/svg_fixtures.dart';

void main() {
  group('Test launching svgcleaner', () {
    test('Test it changes nothing when not installed', () async {
      var task = SvgToRiveTask();
      var dirtyFoo = 'foo';
      var cleanedFoo = await task.clean('foo');
      expect(cleanedFoo, dirtyFoo);
    });
  });

  group('Test converting svgs', () {
    test('Test small svg', () async {
      var drawable = await SvgParserStateRived(
              xml.parseEvents(electricitySvg), 'rive_key', svgPathFuncs)
          .parse();
      createFromSvg(drawable);
    });

    test('Test keep ids svg', () async {
      var drawable = await SvgParserStateRived(
              xml.parseEvents(electricitySvgWithId), 'rive_key', svgPathFuncs)
          .parse();
      var output = createFromSvg(drawable);
      expect(output.artboards.first.children.last.name, 'polygon_one');
      expect(output.artboards.first.children.first.name, 'path_one');
    });
    test('Test filip', () async {
      var drawable = await SvgParserStateRived(
              xml.parseEvents(filip), 'rive_key', svgPathFuncs)
          .parse();
      createFromSvg(drawable);
    });

    test('Test clean filip', () async {
      var drawable = await SvgParserStateRived(
              xml.parseEvents(cleanFilip), 'rive_key', svgPathFuncs)
          .parse();
      createFromSvg(drawable);
    });

    test('test brain svg', () async {
      var drawable = await SvgParserStateRived(
              xml.parseEvents(brain), 'rive_key', svgPathFuncs)
          .parse();

      RiveFile _riveFile = createFromSvg(drawable);

      var exporter = RuntimeExporter(
          core: _riveFile, info: RuntimeHeader(ownerId: 1, fileId: 1));
      exporter.export();
    });

    test('test clip test svg', () async {
      var drawable = await SvgParserStateRived(
              xml.parseEvents(clipTest), 'rive_key', svgPathFuncs)
          .parse();

      RiveFile _riveFile = createFromSvg(drawable);

      var exporter = RuntimeExporter(
          core: _riveFile, info: RuntimeHeader(ownerId: 1, fileId: 1));
      exporter.export();
    });
    test('alt clip test svg', () async {
      var drawable = await SvgParserStateRived(
              xml.parseEvents(altClipTest), 'rive_key', svgPathFuncs)
          .parse();

      RiveFile _riveFile = createFromSvg(drawable);

      var exporter = RuntimeExporter(
          core: _riveFile, info: RuntimeHeader(ownerId: 1, fileId: 1));
      exporter.export();
    });
    test('gradient test svg', () async {
      var drawable = await SvgParserStateRived(
              xml.parseEvents(gradientTest), 'rive_key', svgPathFuncs)
          .parse();

      RiveFile _riveFile = createFromSvg(drawable);
      expect(_riveFile.artboards.first.children.length, 3);

      var linearGradients =
          getChildrenOfType<LinearGradient>(_riveFile.artboards.first).toList();
      var radialGradients =
          getChildrenOfType<RadialGradient>(_riveFile.artboards.first).toList();

      // (all radial gradients are also linear gradiens)
      expect(linearGradients.length, 3);
      expect(radialGradients.length, 2);
      expect(linearGradients.first.startX, 10.0);
      expect(linearGradients.first.startY, 230.0);
      expect(linearGradients.first.endX, 10.0);
      expect(linearGradients.first.endY, 330.0);

      expect(radialGradients.first.startX, 35.0);
      expect(radialGradients.first.startY, 145.0);

      expect(radialGradients[1].startX, 60.0);
      expect(radialGradients[1].startY, 60.0);

      var exporter = RuntimeExporter(
          core: _riveFile, info: RuntimeHeader(ownerId: 1, fileId: 1));
      exporter.export();
    });
    test('hulk mask test', () async {
      var drawable = await SvgParserStateRived(
              xml.parseEvents(mini_hulk), 'rive_key', svgPathFuncs)
          .parse();

      RiveFile _riveFile = createFromSvg(drawable);

      var exporter = RuntimeExporter(
          core: _riveFile, info: RuntimeHeader(ownerId: 1, fileId: 1));
      exporter.export();
    });

    test('male snip test', () async {
      var drawable = await SvgParserStateRived(
              xml.parseEvents(male_snip), 'rive_key', svgPathFuncs)
          .parse();

      RiveFile _riveFile = createFromSvg(drawable);

      var exporter = RuntimeExporter(
          core: _riveFile, info: RuntimeHeader(ownerId: 1, fileId: 1));
      exporter.export();
    });
  });

  const flareRevisionFiles = [
    'bones',
    'circles_revision',
    'clip_simple',
    'gradient',
    'interpolation',
    'keyframe_gradient',
    'keyframes',
    'lottie_circle_revision',
    'path_vertices',
    'simple_path_revision',
    'stroke_color',
    'stroke_gradient',
    'vertex_path_revision'
  ];

  String getPrefix() => Directory.current.path.endsWith('/test') ? '..' : '.';

  RiveFile flareToRive(String revisionFile) {
    // Make sure that resources are properly fetched when running tests
    // with VSCode or with /dev/test_all.sh
    final prefix = getPrefix();
    final fileString =
        File('$prefix/test_resources/$revisionFile.json').readAsStringSync();
    expect(fileString.isNotEmpty, true);
    final converter = FlareToRive(revisionFile)..toFile(fileString);
    return converter.riveFile;
  }

  void convertFlareRevision(String filename) {
    final riveFile = flareToRive(filename);
    final exporter = RuntimeExporter(
      core: riveFile,
      info: RuntimeHeader(ownerId: 0, fileId: 0, version: riveVersion),
    );

    final bytes = exporter.export();
    final prefix = getPrefix();
    File('$prefix/out/$filename.riv')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes, flush: true);
  }

  test('Converts all test files', () {
    flareRevisionFiles.forEach(convertFlareRevision);
  });

  test('Convert bones', () {
    // This is a file with a simple bone chain.
    final riveFile = flareToRive('bones');
    final bones = riveFile.objects.whereType<Bone>();

    bones.forEach((element) {
      element.calculateWorldTransform();
    });

    assert(bones.length == 2);
    assert(bones.first is RootBone);

    final boneIterator = bones.iterator..moveNext();
    final rootBone = boneIterator.current as RootBone;

    assert(rootBone.length == 0);
    assert(rootBone.x == 254.0);
    assert(rootBone.y == 227.5);
    print(rootBone.rotation);

    boneIterator.moveNext();
    final bone = boneIterator.current;
    print(bone.rotation);

    assert(bone.length > 271 && bones.length < 272);
  });

  test('Convert clipping', () {
    // This file contains two shapes, an ellipse and a rectangle,
    //  with the ellipse clipping the rectangle.
    final riveFile = flareToRive('clipping');
    final cs = riveFile.objects.firstWhere((o) => o is ClippingShape);

    assert(cs != null);
    final clipping = cs as ClippingShape;
    final clipped = clipping.parent;
    final clipSource = clipping.source;

    assert(clipped is Shape);
    assert(clipSource is Shape);
    assert(clipped.name == 'Ellipse');
    assert(clipSource.name == 'Rectangle');
  });

  test('Convert fill', () {
    // This file contains two shapes, an ellipse and a rectangle,
    //  with the ellipse clipping the rectangle.
    final riveFile = flareToRive('fill');
    final s = riveFile.objects.firstWhere((o) => o is Shape);

    assert(s != null);
    final shape = s as Shape;
    assert(shape.children.length == 4);

    final fills = shape.children.whereType<Fill>();
    assert(fills.length == 1);

    final fill = fills.first;
    final fillColor = fill.paint.color;
    assert(fillColor.red == (0.9833333492279053 * 255).toInt());
    assert(fillColor.blue == (0.12291666865348816 * 255).toInt());
    assert(fillColor.green == (0.12291666865348816 * 255).toInt());
    assert(fillColor.alpha == 255);

    final strokes = shape.children.whereType<Stroke>();
    assert(strokes.length == 1);

    final stroke = strokes.first;
    final strokeColor = stroke.paint.color;
    assert(strokeColor.red == (0.800000011920929 * 255).toInt());
    assert(strokeColor.blue == (0.800000011920929 * 255).toInt());
    assert(strokeColor.green == (0.800000011920929 * 255).toInt());
  });
}

Iterable<T> getChildrenOfType<T>(ContainerComponent component) sync* {
  var queue = <ContainerComponent>[component];
  while (queue.isNotEmpty) {
    var next = queue.removeAt(0);
    for (var i = 0; i < next.children.length; i++) {
      var child = next.children[i];
      if (child is ContainerComponent) {
        queue.add(child);
      }
      if (child is T) yield child as T;
    }
  }
}
