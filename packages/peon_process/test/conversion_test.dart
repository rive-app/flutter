import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:peon_process/src/helpers/convert_svg.dart';
import 'package:peon_process/src/helpers/flare_to_rive.dart';
import 'package:peon_process/src/tasks/svg_to_rive.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/runtime/runtime_exporter.dart';
import 'package:rive_core/runtime/runtime_header.dart';
import 'package:xml/xml_events.dart' as xml show parseEvents;
import 'package:flutter_svg/src/svg/parser_state.dart';

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
      expect(output.artboards.first.children.first.name, 'polygon_one');
      expect(output.artboards.first.children.last.name, 'path_one');
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
  });

  const flareRevisionFiles = [
    'circles_revision',
    'gradient_revision',
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

  void convertFlareRevision(String filename) {
    // Pick one of the files in the `test_resouces` folder.
    final fileString = File('test_resources/$filename.json').readAsStringSync();
    expect(fileString.isNotEmpty, true);
    int ownerId = 0; // TODO: should be a real one
    final converter = FlareToRive(filename)..toFile(fileString);
    final exporter = RuntimeExporter(
      core: converter.riveFile,
      info: RuntimeHeader(ownerId: ownerId, fileId: 0),
    );
    final bytes = exporter.export();
    var file = File('out/$filename.riv');
    file.create(recursive: true);
    file.writeAsBytesSync(bytes, flush: true);
  }

  test('Converts Flare revision to Rive', () {
    convertFlareRevision('multiple_paths');
  });

  test('Converts all test files', () {
    flareRevisionFiles.forEach(convertFlareRevision);
  });
}
