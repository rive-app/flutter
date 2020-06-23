import 'package:flutter_test/flutter_test.dart';

import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/shapes/ellipse.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/rive/stage/tools/auto_tool.dart';
import 'package:rive_editor/rive/stage/tools/ellipse_tool.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/rectangle_tool.dart';

import 'helpers/test_helpers.dart';

void main() {
  group('EllipseTool', () {
    EllipseTool instance;

    setUp(() => instance = EllipseTool.instance);

    test('Check instance', () => expect(instance != null, true));

    test('Check for icon name',
        () => expect(instance.icon, PackedIcon.toolEllipse));

    test('create ellipse test', () async {
      // TestWidgetsFlutterBinding.ensureInitialized();

      var file = await makeFile();
      var core = file.core;
      var stage = file.stage;

      // Place the mouse at an initial position...
      stage.mouseMove(1, 100, 100);

      // Select the pen tool and expect it to validate.
      stage.tool = EllipseTool.instance;
      expect(stage.tool, EllipseTool.instance);

      // Click and drag from 100, 100 to 300, 200
      stage.mouseDown(1, 100, 100);
      stage.mouseDrag(1, 100, 100);

      stage.mouseDrag(1, 300, 200);
      stage.mouseUp(1, 300, 200);

      expect(core.objectsOfType<Shape>().length, 1,
          reason: 'there should be one shape after clicking the pen tool');
      expect(core.objectsOfType<Ellipse>().length, 1,
          reason: 'there should be one ellipse');

      var shape = core.objectsOfType<Shape>().first;
      var ellipse = core.objectsOfType<Ellipse>().first;
      expect(
          Mat2D.areEqual(shape.worldTransform,
              Mat2D.fromTranslation(Vec2D.fromValues(100, 100))),
          true);
      expect(ellipse.width, 200);
      expect(ellipse.height, 100);

      file.advance(0);

      stage.tool = AutoTool.instance;
      // Move mouse to trigger hover...
      stage.mouseMove(1, 150, 150);
      expect(stage.hoverItem, shape.stageItem);

      // Select hovered item
      stage.mouseDown(1, 150, 150);
      expect(file.selection.items.contains(shape.stageItem), true,
          reason: 'should\'ve selected the ellipse shape');

      stage.mouseDrag(1, 150, 150);

      // move 50 pixels on x
      stage.mouseDrag(1, 200, 150);
      stage.mouseUp(1, 200, 150);
      file.advance(0);

      expect(
          Mat2D.areEqual(shape.worldTransform,
              Mat2D.fromTranslation(Vec2D.fromValues(150, 100))),
          true,
          reason:
              'expect the shape to have moved 50 pixels from 100 to 150 on x');
    });
  });

  group('RectangleTool', () {
    RectangleTool instance;

    setUp(() => instance = RectangleTool.instance);

    test('Check instance', () => expect(instance != null, true));

    test('Check for icon name',
        () => expect(instance.icon, PackedIcon.toolRectangle));
  });
}
