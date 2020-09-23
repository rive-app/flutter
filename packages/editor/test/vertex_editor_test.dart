import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rive_core/shapes/cubic_detached_vertex.dart';
import 'package:rive_core/shapes/cubic_mirrored_vertex.dart';
import 'package:rive_core/shapes/points_path.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:rive_core/shapes/straight_vertex.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/rive/stage/items/stage_path.dart';
import 'package:rive_editor/rive/stage/tools/vector_pen_tool.dart';
import 'package:rive_editor/rive/vertex_editor.dart';
import 'package:rive_editor/widgets/common/multi_toggle.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'helpers/inspector_helper.dart';
import 'helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('enter and exit vertex editor', () async {
    var file = await makeFile();
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

    stage.mouseMove(1, 100, 200);
    stage.mouseDown(1, 100, 200);
    stage.mouseUp(1, 100, 200);
    expect(editingPath.vertices.length, 2,
        reason: 'after second click, path should have two points');
    expect(editingPath.vertices[1].x, 0);
    expect(editingPath.vertices[1].y, 100);

    stage.mouseMove(1, 200, 200);
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

  testWidgets('subdivide a path', (tester) async {
    /// Test for issue #800.
    var file = await makeFile();
    var core = file.core;
    expect(core.backboard != null, true);
    expect(core.backboard.activeArtboard != null, true);

    var stage = file.stage;
    expect(stage != null, true);

    // Select the pen tool and expect it to validate.
    stage.tool = VectorPenTool.instance;
    expect(stage.tool, VectorPenTool.instance);

    stage.mouseMove(1, 100, 100);
    stage.mouseDown(1, 100, 100);
    stage.mouseUp(1, 100, 100);

    stage.mouseMove(1, 200, 100);
    stage.mouseDown(1, 200, 100);
    stage.mouseUp(1, 200, 100);

    expect(core.objectsOfType<PointsPath>().length, 1);

    var pointsPath = core.objectsOfType<PointsPath>().first;
    expect(pointsPath.vertices.length, 2);

    var vtx1 = pointsPath.vertices[0];
    expect(vtx1.x, 0);
    expect(vtx1.y, 0);
    var vtx2 = pointsPath.vertices[1];
    expect(vtx2.x, 100);
    expect(vtx2.y, 0);

    stage.mouseMove(1, 150, 100);
    stage.mouseDown(1, 150, 100);
    stage.mouseUp(1, 150, 100);

    expect(pointsPath.vertices.length, 3);

    // vtx2 should now be the third vertex
    expect(pointsPath.vertices[2], vtx2);
    var insertedVertex = pointsPath.vertices[1];
    expect(insertedVertex.x, 50);
    expect(insertedVertex.y, 0);

    insertedVertex.remove();
    file.core.captureJournalEntry();
    expect(pointsPath.vertices.length, 2);

    // Make an instance of the vertex inspector to test changing the vertices to
    // cubics.
    file.select(vtx1.stageItem);
    file.select(vtx2.stageItem, append: true);

    await tester.pumpWidget(TestInspector(file: file));

    var multiToggle = find.byType(MultiToggle<int>().runtimeType);

    var detectors = find.descendant(
        of: multiToggle, matching: find.byType(GestureDetector));

    expect(detectors.evaluate().length, 4,
        reason:
            'Expect 4 vertex type options to click on inside the multitoggle.');

    // Click on the 2nd one which is type mirrored.
    await tester.tap(detectors.at(1));
    await tester.pumpAndSettle();
    file.advance(0);

    vtx1 = pointsPath.vertices[0];
    vtx2 = pointsPath.vertices[1];
    expect(vtx1.runtimeType, CubicMirroredVertex);
    expect(vtx2.runtimeType, CubicMirroredVertex);

    if (vtx1 is CubicMirroredVertex) {
      vtx1.rotation = -pi / 2;
      vtx1.distance = 10;
    }
    if (vtx2 is CubicMirroredVertex) {
      vtx2.rotation = -pi * 1.5;
      vtx2.distance = 10;
    }

    // Move to 50, -7
    // origin is at 100, 100
    stage.mouseMove(1, 150, 93);
    stage.mouseDown(1, 150, 93);
    stage.mouseUp(1, 150, 93);

    // Wait for any debounced logic the mouseMove may trigger to settle. Note we
    // don't do this earlier because we have no UI but once we pump a widget the
    // FakeTimers  activate and need to settle otherwise they'll throw.
    await tester.pumpAndSettle();

    file.core.captureJournalEntry();
    expect(pointsPath.vertices.length, 3,
        reason: 'moving to 150, 93 should\'ve snapped and subdivided');

    // Expect the click to have created a cubic detached vertex
    insertedVertex = pointsPath.vertices[1];
    expect(insertedVertex.runtimeType, CubicDetachedVertex);

    if (insertedVertex is CubicDetachedVertex) {
      // Expect it to be placed between the two on the curve with appropriate
      // rotation and length for the in and out.
      expect(insertedVertex.translation[0], 50);
      expect(insertedVertex.translation[1], -7.5);
      expect(insertedVertex.inRotation, pi);
      expect(insertedVertex.outRotation, 0);
      expect(insertedVertex.inDistance, 25);
      expect(insertedVertex.outDistance, 25);
    }
  });


  test('subdivide a rounded corner', () async {
    /// Test for issue #1302.
    var file = await makeFile();
    var core = file.core;

    var stage = file.stage;
    expect(stage != null, true);

    stage.tool = VectorPenTool.instance;

    stage.mouseMove(1, 100, 100);
    stage.mouseDown(1, 100, 100);
    stage.mouseUp(1, 100, 100);

    stage.mouseMove(1, 200, 100);
    stage.mouseDown(1, 200, 100);
    stage.mouseUp(1, 200, 100);

    stage.mouseMove(1, 200, 200);
    stage.mouseDown(1, 200, 200);
    stage.mouseUp(1, 200, 200);

    expect(core.objectsOfType<PointsPath>().length, 1);

    var pointsPath = core.objectsOfType<PointsPath>().first;
    expect(pointsPath.vertices.length, 3);

    var vtx2 = pointsPath.vertices[1];
    expect(vtx2.x, 100);
    expect(vtx2.y, 0);
    // Turn it into a rounded corner.
    (vtx2 as StraightVertex).radius = 20;

    file.advance(0);

    // Click on the corner.
    stage.mouseMove(1, 193.6, 105.3);
    stage.mouseDown(1, 193.6, 105.3);
    stage.mouseUp(1, 193.6, 105.3);

    // There should now be 5 points as the corner was replaced with 3 cubic
    // points.
    expect(pointsPath.vertices.length, 5);

    var cubic1 = pointsPath.vertices[1];
    var cubic2 = pointsPath.vertices[2];
    var cubic3 = pointsPath.vertices[3];

    expect(cubic1 is CubicDetachedVertex, true);
    expect(cubic2 is CubicDetachedVertex, true);
    expect(cubic3 is CubicDetachedVertex, true);

    core.captureJournalEntry();

    // Make sure we can undo the split.
    core.undo();
    expect(pointsPath.vertices.length, 3);
    expect(pointsPath.vertices[1] is StraightVertex, true);
  });
}
