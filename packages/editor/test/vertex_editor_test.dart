import 'package:flutter_test/flutter_test.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/shapes/points_path.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:rive_core/shapes/straight_vertex.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/rive/stage/tools/vector_pen_tool.dart';

import 'helpers/test_open_file_context.dart';

Future<OpenFileContext> _makeFile() async {
  var file = TestOpenFileContext();
  expect(await file.fakeConnect(), true);

  // file will already have a backboard for us, adding an artboard will
  // automatically make it the active one.

  // Make a somewhat sane file.
  Artboard artboard;
  var core = file.core;
  core.batchAdd(() {
    artboard = Artboard()
      ..name = 'My Artboard'
      ..x = 0
      ..y = 0
      ..width = 1920
      ..height = 1080;

    core.add(artboard);
  });
  core.captureJournalEntry();
  return file;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('enter and exit vertex editor', () async {
    var file = await _makeFile();
    var core = file.core;
    expect(core.backboard != null, true);
    expect(core.backboard.activeArtboard != null, true);

    var stage = file.stage;
    expect(stage != null, true);

    // Select the pen tool and expect it to validate.
    stage.tool = VectorPenTool.instance;
    expect(stage.tool, VectorPenTool.instance);

    // Expect there to be no shapes, paths, or vertices prior to clicking.
    expect(core.objectsOfType<Shape>().isEmpty, true);
    expect(core.objectsOfType<PointsPath>().isEmpty, true);
    expect(core.objectsOfType<StraightVertex>().isEmpty, true);

    // Click on the stage and expect it to create a shape, path, and one vertex.
    stage.mouseDown(1, 100, 100);

    expect(core.objectsOfType<Shape>().length, 1);
    expect(core.objectsOfType<PointsPath>().length, 1);
    expect(core.objectsOfType<StraightVertex>().length, 1);
  });
}
