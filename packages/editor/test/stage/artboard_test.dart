import 'package:flutter_test/flutter_test.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_editor/rive/stage/tools/artboard_tool.dart';
import 'package:rive_editor/rive/stage/tools/auto_tool.dart';

import '../helpers/test_helpers.dart';

void main() {
  test('create artboard test', () async {
    // TestWidgetsFlutterBinding.ensureInitialized();

    var file = await makeFile(addArtboard: false);
    var core = file.core;
    var stage = file.stage;

    // There's no default artboard
    expect(core.objectsOfType<Artboard>().length, 0,
        reason: 'there should be no default artboard');

    // Place the mouse at an initial position...
    stage.mouseMove(1, 100, 100);

    // Select the artboard tool and expect it to validate.
    stage.tool = ArtboardTool.instance;
    expect(stage.tool, ArtboardTool.instance);

    // Click and drag from 100, 100 to 300, 200
    stage.mouseDown(1, 100, 100);
    stage.mouseDrag(1, 100, 100);

    stage.mouseDrag(1, 500, 400);
    stage.mouseUp(1, 500, 400);

    // Autotool should be selected when tool has created an artboard
    expect(stage.tool, AutoTool.instance);

    expect(core.objectsOfType<Artboard>().length, 1,
        reason: 'there should be one artboard');

    var artboard = core.objectsOfType<Artboard>().first;
    expect(artboard.x, 100);
    expect(artboard.y, 100);
    expect(artboard.width, 400);
    expect(artboard.height, 300);

    stage.tool = ArtboardTool.instance;
    stage.mouseDown(1, 250, 250);
    stage.mouseDrag(1, 250, 250);

    stage.mouseDrag(1, 500, 500);
    stage.mouseUp(1, 500, 500);

    expect(stage.tool, AutoTool.instance);

    expect(core.objectsOfType<Artboard>().length, 2,
        reason: 'there should be one artboard');

    artboard = core.objectsOfType<Artboard>().first;
    expect(artboard.x, 250);
    expect(artboard.y, 250);
    expect(artboard.width, 250);
    expect(artboard.height, 250);
  });
}
