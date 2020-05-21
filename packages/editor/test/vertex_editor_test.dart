import 'package:flutter_test/flutter_test.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/shapes/points_path.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:rive_core/shapes/straight_vertex.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/rive/stage/items/stage_path.dart';
import 'package:rive_editor/rive/stage/tools/vector_pen_tool.dart';
import 'package:rive_editor/rive/vertex_editor.dart';

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

    // Place the mouse at an initial position...
    stage.mouseMove(1, 100, 100);

    // Select the pen tool and expect it to validate.
    stage.tool = VectorPenTool.instance;
    expect(stage.tool, VectorPenTool.instance);

    // Expect there to be no shapes, paths, or vertices prior to clicking.
    expect(core.objectsOfType<Shape>().isEmpty, true);
    expect(core.objectsOfType<PointsPath>().isEmpty, true);
    expect(core.objectsOfType<StraightVertex>().isEmpty, true);

    // Expect vertex editor to think it's not doing anything
    expect(file.vertexEditor.mode.value, VertexEditorMode.off);

    // Click on the stage and expect it to create a shape, path, and one vertex.
    stage.mouseDown(1, 100, 100);
    stage.mouseUp(1, 100, 100);

    expect(core.objectsOfType<Shape>().length, 1,
        reason: 'there should be one shape after clicking the pen tool');
    expect(core.objectsOfType<PointsPath>().length, 1,
        reason: 'there should be one points path');
    expect(core.objectsOfType<StraightVertex>().length, 1,
        reason: 'there should be one vertex');

    // give stage the chance to sync (run any debounced operations).
    expect(file.stage.soloItems == null, true);
    file.advance(0);
    expect(file.stage.soloItems != null, true);

    expect(file.stage.soloItems.length, 1);
    expect(file.stage.soloItems.first is StagePath, true);

    // Expect vertex editor to be in editingPath mode.
    expect(file.vertexEditor.mode.value, VertexEditorMode.editingPath);

    var editingShape = core.objectsOfType<Shape>().first;
    expect(editingShape.paths.length, 1,
        reason: 'editing shape should have one path');

    var editingPath = core.objectsOfType<PointsPath>().first;
    expect(editingShape.x, 100);
    expect(editingShape.y, 100);
    expect(editingPath.x, 0);
    expect(editingPath.y, 0);
    expect(editingPath.vertices.first.x, 0);
    expect(editingPath.vertices.first.y, 0);

    expect(editingPath.editingMode, PointsPathEditMode.creating,
        reason: 'Path should be in creation mode.');

    stage.mouseDown(1, 100, 200);
    stage.mouseUp(1, 100, 200);
    expect(editingPath.vertices.length, 2,
        reason: 'after second click, path should have two points');
    expect(editingPath.vertices[1].x, 0);
    expect(editingPath.vertices[1].y, 100);

    stage.mouseDown(1, 200, 200);
    stage.mouseUp(1, 200, 200);
    expect(editingPath.vertices.length, 3,
        reason: 'after second click, path should have three points');
    expect(editingPath.vertices[2].x, 100);
    expect(editingPath.vertices[2].y, 100);

    // Undo should remove the last point.
    expect(core.undo(), true);

    expect(editingPath.vertices.length, 2,
        reason: 'after undo, path should have two points');

    // redo should add the third point.
    expect(core.redo(), true);

    expect(editingPath.vertices.length, 3,
        reason: 'after second click, path should have three points');
    expect(editingPath.vertices[2].x, 100);
    expect(editingPath.vertices[2].y, 100);

    // Sending escape key should exit edit mode.
    file.triggerAction(ShortcutAction.cancel);
    expect(file.vertexEditor.mode.value, VertexEditorMode.off);
    expect(editingPath.editingMode, PointsPathEditMode.off,
        reason: 'Path should no longer be in creation mode.');

    // Undoing at this point should put us back in edit mode.
    expect(core.undo(), true);

    expect(file.vertexEditor.mode.value, VertexEditorMode.editingPath);
    expect(editingPath.editingMode, PointsPathEditMode.creating,
        reason: 'Path should go back to creation mode.');
    expect(editingPath.vertices.length, 3);

    expect(core.undo(), true);
    expect(editingPath.vertices.length, 2);

    expect(core.undo(), true);
    expect(editingPath.vertices.length, 1);

    expect(core.undo(), true);

    // Expect the shape and path to no longer be in the file.
    expect(file.core.isHolding(editingShape), false);
    expect(file.core.isHolding(editingPath), false);

    // Expect there to be no shapes, paths, or vertices as we undid all the way
    // to the creation of th eshape.
    expect(core.objectsOfType<Shape>().isEmpty, true);
    expect(core.objectsOfType<PointsPath>().isEmpty, true);
    expect(core.objectsOfType<StraightVertex>().isEmpty, true);

    expect(file.vertexEditor.mode.value, VertexEditorMode.off,
        reason: "editor mode should be off now that the path was removed");

    expect(core.redo(), true);

    // When we redo the creation of a shape, the references are new (we instance
    // new objects).
    expect(core.objectsOfType<Shape>().length, 1);
    expect(core.objectsOfType<PointsPath>().length, 1);
    expect(core.objectsOfType<StraightVertex>().length, 1);

    // Expect vertex editor to be in editingPath mode.
    expect(file.vertexEditor.mode.value, VertexEditorMode.editingPath);

    var reEditingPath = core.objectsOfType<PointsPath>().first;
    expect(reEditingPath.editingMode, PointsPathEditMode.creating,
        reason: 'Path should go back to creation mode.');
  });
}
