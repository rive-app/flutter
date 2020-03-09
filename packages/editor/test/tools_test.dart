import 'package:flutter_test/flutter_test.dart';
import 'package:rive_editor/rive/stage/tools/ellipse_tool.dart';
import 'package:rive_editor/rive/stage/tools/rectangle_tool.dart';

void main() {
  group("EllipseTool", () {
    EllipseTool instance;

    setUp(() {
      instance = EllipseTool.instance;
    });

    test('Check instance', () {
      expect(instance != null, true);
    });

    test('Check for icon name', () {
      expect(instance.icon, 'tool-ellipse');
    });
  });

  group("RectangleTool", () {
    RectangleTool instance;

    setUp(() {
      instance = RectangleTool.instance;
    });

    test('Check instance', () {
      expect(instance != null, true);
    });

    test('Check for icon name', () {
      expect(instance.icon, 'tool-rectangle');
    });
  });
}
