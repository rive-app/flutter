import 'dart:io';

import 'package:flutter_svg/src/svg/parser_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peon_process/src/helpers/convert_svg.dart';
import 'package:peon_process/src/helpers/flare_to_rive.dart';
import 'package:peon_process/src/helpers/svg_utils/paths.dart';
import 'package:peon_process/src/tasks/flare_to_rive.dart';
import 'package:peon_process/src/tasks/svg_to_rive.dart';
import 'package:rive_core/bones/bone.dart';
import 'package:rive_core/bones/root_bone.dart';
import 'package:rive_core/bones/skin.dart';
import 'package:rive_core/bones/tendon.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/runtime/runtime_exporter.dart';
import 'package:rive_core/runtime/runtime_header.dart';
import 'package:rive_core/shapes/clipping_shape.dart';
import 'package:rive_core/shapes/cubic_detached_vertex.dart';
import 'package:rive_core/shapes/cubic_vertex.dart';
import 'package:rive_core/shapes/paint/fill.dart';
import 'package:rive_core/shapes/paint/linear_gradient.dart';
import 'package:rive_core/shapes/paint/radial_gradient.dart';
import 'package:rive_core/shapes/paint/stroke.dart';
import 'package:rive_core/shapes/path_vertex.dart';
import 'package:rive_core/shapes/points_path.dart';
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

    expect(bones, hasLength(2));
    expect(bones.first, isInstanceOf<RootBone>());

    final boneIterator = bones.iterator..moveNext();
    final rootBone = boneIterator.current as RootBone;

    expect(rootBone.length, equals(0));
    expect(rootBone.x, equals(254.0));
    expect(rootBone.y, equals(227.5));
    print(rootBone.rotation);

    boneIterator.moveNext();
    final bone = boneIterator.current;
    print(bone.rotation);

    expect(bone.length, equals(271.26555254952666));
  });

  test('Convert clipping', () {
    // This file contains two shapes, an ellipse and a rectangle,
    //  with the ellipse clipping the rectangle.
    final riveFile = flareToRive('clipping');
    final cs = riveFile.objects.firstWhere((o) => o is ClippingShape);

    expect(cs, isNotNull);
    final clipping = cs as ClippingShape;
    final clipped = clipping.parent;
    final clipSource = clipping.source;

    expect(clipped, isInstanceOf<Shape>());
    expect(clipSource, isInstanceOf<Shape>());
    expect(clipped.name, equals('Ellipse'));
    expect(clipSource.name, equals('Rectangle'));
  });

  test('Convert fill', () {
    // This file contains two shapes, an ellipse and a rectangle,
    //  with the ellipse clipping the rectangle.
    final riveFile = flareToRive('fill');
    final s = riveFile.objects.firstWhere((o) => o is Shape);

    expect(s, isNotNull);
    final shape = s as Shape;
    expect(shape.children, hasLength(4));

    final fills = shape.children.whereType<Fill>();
    expect(fills, hasLength(1));

    final fill = fills.first;
    final fillColor = fill.paint.color;

    expect(fillColor.red, equals((0.9833333492279053 * 255).toInt()));
    expect(fillColor.blue, equals((0.12291666865348816 * 255).toInt()));
    expect(fillColor.green, equals((0.12291666865348816 * 255).toInt()));
    expect(fillColor.alpha, equals(255));

    final strokes = shape.children.whereType<Stroke>();
    expect(strokes, hasLength(1));

    final stroke = strokes.first;
    final strokeColor = stroke.paint.color;
    expect(strokeColor.red, equals((0.800000011920929 * 255).toInt()));
    expect(strokeColor.blue, equals((0.800000011920929 * 255).toInt()));
    expect(strokeColor.green, equals((0.800000011920929 * 255).toInt()));
  });

  test('Convert skin', () {
    final riveFile = flareToRive('skin');
    final skins = riveFile.objects.whereType<Skin>();
    expect(skins, hasLength(1));

    final skin = skins.first;
    final skinnable = skin.parent;
    expect(skinnable, isInstanceOf<PointsPath>());
    expect(skin.worldTransform[4], equals(803));
    expect(skin.worldTransform[5], equals(184.49998474121094));

    final tendons = skin.children.whereType<Tendon>();
    expect(tendons, hasLength(5));

    final tendon = tendons.first;
    // Make sure bind matrix is correct.
    expect(tendon.xx, equals(0.997778594493866));
    expect(tendon.xy, equals(0.06661725789308548));
    expect(tendon.yx, equals(-0.06661725789308548));
    expect(tendon.yy, equals(0.997778594493866));
    expect(tendon.tx, equals(254));
    expect(tendon.ty, equals(227.5));

    final firstConnectedBone = tendons.first.bone as Bone;
    // Make sure tendon is bound to the right bone.
    expect(firstConnectedBone, isNotNull);
    expect(firstConnectedBone.parent, isInstanceOf<RootBone>());
    expect(firstConnectedBone.length, equals(271.26555254952666));

    // Check weights.
    final vertices = skinnable.children.whereType<PathVertex>();
    expect(vertices, hasLength(4));
    final cubicVertices = skinnable.children.whereType<CubicVertex>();
    expect(cubicVertices, hasLength(2));

    final cubicDetachedVertex =
        cubicVertices.whereType<CubicDetachedVertex>().first;

    // Make sure weights & indices are byte-to-byte correct.
    expect(cubicDetachedVertex.weight.values, equals(0x2d541c5f));
    expect(cubicDetachedVertex.weight.indices, equals(0x05030201));
  });

  test('Convert flr2d file', () async {
    final prefix = getPrefix();
    final data = {
      'params': {'notifyUserId': 0}
    };
    final task = FlareToRiveTask.fromData(data);
    final flareBytes =
        File('$prefix/test_resources/flr2d/Bones.flr2d').readAsBytesSync();
    final riveBytes = task.generateRive(flareBytes);
    expect(riveBytes, isNotNull);
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
