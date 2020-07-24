import 'package:flutter_test/flutter_test.dart';
import 'package:peon_process/src/tasks/svg_to_rive.dart';

void main() {
  group('Test launching svgcleaner', () {
    test('Test it changes nothing when not installed', () async {
      var task = SvgToRiveTask();
      var dirtyFoo = 'foo';
      var cleanedFoo = await task.clean('foo');
      expect(cleanedFoo, dirtyFoo);
    });
  });
}
