import 'package:flutter_test/flutter_test.dart';

import 'package:rive_core/shapes/rectangle.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/rive/stage/tools/rectangle_tool.dart';
import 'package:rive_editor/rive/stage/tools/translate_tool.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('TranslateTool', () {
    TranslateTool translateTool;

    setUp(() => translateTool = TranslateTool.instance);

    test('Check instance', () => expect(translateTool != null, true));

    test('Check for icon name',
        () => expect(translateTool.icon, PackedIcon.toolTranslate));

    test('Items can be translated', () async {
      var file = await makeFile();
      var core = file.core;
      var stage = file.stage;

      // Place the mouse at an initial position...
      stage.mouseMove(1, 100, 100);

      // Select the rectangle tool and draw a rectangle
      stage.tool = RectangleTool.instance;
      stage.mouseDown(1, 100, 100);
      stage.mouseDrag(1, 100, 100);
      stage.mouseDrag(1, 300, 200);
      stage.mouseUp(1, 300, 200);

      final rect = core.objectsOfType<Rectangle>().first;
      final shape = rect.shape;
      final stageShape = shape.stageItem;

      // Position of the rectangle's shape should be (100, 100)
      expect(shape.x, 100);
      expect(shape.y, 100);
      expect(rect.width, 200);
      expect(rect.height, 100);

      // Select the rectangle with the mouse
      stage.mouseMove(1, 150, 150);
      stage.mouseDown(1, 150, 150);
      stage.mouseUp(1, 150, 150);

      expect(file.selection.first, stageShape,
          reason: 'Shape should be selected');

      // Select the translate tool
      stage.tool = translateTool;
      expect(stage.tool, TranslateTool.instance);

      print("MOVE STUFF!");
      // Translate the rectangle by (50, 50)
      stage.mouseDown(1, 150, 150);
      stage.mouseDrag(1, 150, 150);
      stage.mouseDrag(1, 200, 200);
      stage.mouseUp(1, 200, 200);

      // Position of the rectangle
      expect(shape.x, 150);
      expect(shape.y, 150);

      // Select the shape
      file.select(stageShape);
      expect(file.selection.first, stageShape);

      // Translate by (50, 50) by holding down mouse button and dragging
      stage.mouseMove(1, 0, 0);
      stage.mouseDown(1, 0, 0);
      stage.mouseDrag(1, 0, 0);
      stage.mouseDrag(1, 50, 50);
      stage.mouseUp(1, 50, 50);

      // Position of the shape should now be (200, 200)
      expect(shape.x, 200);
      expect(shape.y, 200);
    });
  });
}
