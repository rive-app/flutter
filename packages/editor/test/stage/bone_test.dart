import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:rive_core/bones/bone.dart';
import 'package:rive_core/bones/root_bone.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/rive/stage/tools/auto_tool.dart';
import 'package:rive_editor/rive/stage/tools/bone_tool.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/translate_tool.dart';

import '../helpers/test_helpers.dart';

void main() {
  BoneTool instance;

  setUp(() => instance = BoneTool.instance);

  test('Check instance', () => expect(instance != null, true));

  test('Check for icon name', () => expect(instance.icon, PackedIcon.toolBone));

  test('Bones can be created on stage', () async {
    final file = await makeFile(); // also makes an artboard
    final core = file.core;
    final stage = file.stage;

    // select the bone tool
    stage.tool = instance;

    // click at (100, 100)
    stage.mouseMove(1, 100, 100);
    stage.mouseDown(1, 100, 100);
    stage.mouseUp(1, 100, 100);

    // click at (200, 200)
    stage.mouseMove(1, 200, 200);
    stage.mouseDown(1, 200, 200);
    stage.mouseUp(1, 200, 200);

    // the tool should still be the bone tool when mouse is released
    expect(stage.tool, BoneTool.instance);

    // we should now have a root bone
    expect(core.objectsOfType<RootBone>().length, 1,
        reason: 'a root bone should have been created');

    final rootBone = core.objectsOfType<RootBone>().first;

    // root bone properties are correct?
    expect(rootBone.x, 100);
    expect(rootBone.y, 100);
    expect(rootBone.rotation, math.pi / 4);
    expect(rootBone.length, 100 * math.sqrt(2));

    // click at (200, 300)
    stage.mouseMove(1, 200, 300);
    stage.mouseDown(1, 200, 300);
    stage.mouseUp(1, 200, 300);

    // we should still have one root bone
    expect(core.objectsOfType<RootBone>().length, 1,
        reason: 'no new root bone should have been created');

    // we have two bones (one root, one regular)
    expect(core.objectsOfType<Bone>().length, 2,
        reason: 'a new bone should have been created');

    final firstBone = core.objectsOfType<Bone>().toList()[0];

    // first bone properties are correct?
    expect(firstBone.x, 100 * math.sqrt(2)); // same as length of previous bone
    expect(firstBone.y, 0);
    expect(firstBone.rotation, math.pi / 4); // same as rotation as root bone
    expect(firstBone.length.round(), 100);

    // click at (300, 300)
    stage.mouseMove(1, 300, 300);
    stage.mouseDown(1, 300, 300);
    stage.mouseUp(1, 300, 300);

    // we have three bones (one root, two regular)
    expect(core.objectsOfType<Bone>().length, 3,
        reason: 'a new bone should have been created');

    final secondBone = core.objectsOfType<Bone>().toList()[0];

    // second bone properties are correct?
    expect(secondBone.x.round(), 100); // same as length of previous bone
    expect(secondBone.y, 0);
    expect(firstBone.rotation, math.pi / 4); // same as rotation as root bone
    expect(secondBone.length.round(), 100);

    // hit escape
    file.triggerAction(ShortcutAction.cancel);

    // auto tool should now be selected
    expect(stage.tool, AutoTool.instance);
  });

  test('Bones can be transformed', () async {
    final file = await makeFile(); // also makes an artboard
    final core = file.core;
    final stage = file.stage;

    // select the bone tool
    stage.tool = instance;

    // click at (100, 100)
    stage.mouseMove(1, 100, 100);
    stage.mouseDown(1, 100, 100);
    stage.mouseUp(1, 100, 100);

    // click at (200, 200)
    stage.mouseMove(1, 200, 200);
    stage.mouseDown(1, 200, 200);
    stage.mouseUp(1, 200, 200);

    // the tool should still be the bone tool when mouse is released
    expect(stage.tool, BoneTool.instance);

    // we should now have a root bone
    expect(core.objectsOfType<RootBone>().length, 1,
        reason: 'a root bone should have been created');

    final rootBone = core.objectsOfType<RootBone>().first;
    final stageRootBone = rootBone.stageItem;
    expect(stageRootBone, isNotNull);

    // click at (200, 300)
    stage.mouseMove(1, 200, 300);
    stage.mouseDown(1, 200, 300);
    stage.mouseUp(1, 200, 300);

    final firstBone = core.objectsOfType<Bone>().toList()[0];
    final stageFirstBone = firstBone.stageItem;
    expect(stageFirstBone, isNotNull);

    // click at (300, 300)
    stage.mouseMove(1, 300, 300);
    stage.mouseDown(1, 300, 300);
    stage.mouseUp(1, 300, 300);

    final secondBone = core.objectsOfType<Bone>().toList()[0];
    final stageSecondBone = secondBone.stageItem;
    expect(stageSecondBone, isNotNull);

    // hit escape
    file.triggerAction(ShortcutAction.cancel);

    // Root bone should be at (100, 100)
    expect(rootBone.x, 100);
    expect(rootBone.y, 100);

    // Activate the translation tool
    stage.tool = TranslateTool.instance;

    // Select the root bone
    file.select(stageRootBone);
    expect(file.selection.first, stageRootBone);

    // Translate by (50, 50)
    stage.mouseMove(1, 0, 0);
    stage.mouseDown(1, 0, 0);
    stage.mouseDrag(1, 0, 0);
    stage.mouseDrag(1, 50, 50);
    stage.mouseUp(1, 50, 50);

    // Root bone should now be at (150, 150)
    expect(rootBone.x, 150);
    expect(rootBone.y, 150);
  });
}
