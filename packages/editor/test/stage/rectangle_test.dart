import 'package:flutter_test/flutter_test.dart';

import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/shapes/rectangle.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/rive/stage/tools/auto_tool.dart';
import 'package:rive_editor/rive/stage/tools/rectangle_tool.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('RectangleTool', () {
    RectangleTool instance;

    setUp(() => instance = RectangleTool.instance);

    test('Check instance', () => expect(instance != null, true));

    test('Check for icon name',
        () => expect(instance.icon, PackedIcon.toolRectangle));

    test('Rectangles can be created on stage', () async {
      // TestWidgetsFlutterBinding.ensureInitialized();

      var file = await makeFile();
      var core = file.core;
      var stage = file.stage;

      // Place the mouse at an initial position...
      stage.mouseMove(1, 100, 100);

      // Select the pen tool and expect it to validate.
      stage.tool = instance;
      expect(stage.tool, RectangleTool.instance);

      // Click and drag from 100, 100 to 300, 200
      stage.mouseDown(1, 100, 100);
      stage.mouseDrag(1, 100, 100);

      stage.mouseDrag(1, 300, 200);
      stage.mouseUp(1, 300, 200);

      // The autotool should be automatically selected after rectangle creation
      expect(stage.tool, AutoTool.instance);

      expect(core.objectsOfType<Shape>().length, 1,
          reason: 'there should be one shape after clicking the pen tool');
      expect(core.objectsOfType<Rectangle>().length, 1,
          reason: 'there should be one rectangle');

      var shape = core.objectsOfType<Shape>().first;
      Rectangle rectangle = core.objectsOfType<Rectangle>().first;

      // Position of the rectangle
      expect(rectangle.shape.x, 100);
      expect(rectangle.shape.y, 100);

      // The position of the origin of the rectangle
      // This is the rectangle's midpoint
      expect(rectangle.x, 100);
      expect(rectangle.y, 50);

      // Length of sides of rectangle
      expect(rectangle.width, 200);
      expect(rectangle.height, 100);

      // No hover if mouse isn't over anything
      stage.mouseMove(1, 1000, 1000);
      expect(stage.hoverItem, null);

      // Move mouse to trigger hover...
      stage.mouseMove(1, 150, 150);
      expect(stage.hoverItem, shape.stageItem);

      // Select hovered item
      stage.mouseDown(1, 150, 150);
      expect(file.selection.items.contains(shape.stageItem), true,
          reason: 'Rectangle should be selected');

      stage.mouseDrag(1, 150, 150);
      // move 50 pixels on x
      stage.mouseDrag(1, 200, 150);
      stage.mouseUp(1, 200, 150);

      // Position of the rectangle
      expect(rectangle.shape.x, 150);
      expect(rectangle.shape.y, 100);

      // Check the midpoint
      expect(rectangle.x, 100);
      expect(rectangle.y, 50);

      expect(
          Mat2D.areEqual(
            shape.worldTransform,
            Mat2D.fromTranslation(Vec2D.fromValues(150, 100)),
          ),
          true,
          reason:
              'expect the shape to have moved 50 pixels from 100 to 150 on x');
    });
  });
}
