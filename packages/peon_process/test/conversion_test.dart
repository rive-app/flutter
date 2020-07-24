import 'package:flutter_test/flutter_test.dart';
import 'package:peon_process/src/helpers/convert_svg.dart';
import 'package:peon_process/src/tasks/svg_to_rive.dart';
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
  });
}
