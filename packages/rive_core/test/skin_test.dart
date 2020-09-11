import 'package:flutter_test/flutter_test.dart';
import 'package:local_data/local_data.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/bones/bone.dart';
import 'package:rive_core/bones/root_bone.dart';
import 'package:rive_core/bones/skin.dart';

import 'package:rive_core/shapes/points_path.dart';
import 'package:rive_core/shapes/shape.dart';

import 'src/test_rive_file.dart';

void main() {
  test('binding to bones works', () {
    LocalDataPlatform dataPlatform = LocalDataPlatform.make();

    // Connect client1
    final file = TestRiveFile(
      'fake',
      localDataPlatform: dataPlatform,
      overridePreferences: <String, dynamic>{
        'token': 'fake',
        'clientId': 1,
      },
      useSharedPreferences: false,
    );

    Shape shape;
    PointsPath path;
    Artboard artboard;
    RootBone rootBone;
    Bone bone;
    // Create the node with some name set to it.
    file.batchAdd(() {
      artboard = file.addObject(Artboard());
      shape = file.addObject(Shape());
      path = file.addObject(PointsPath());
      shape.appendChild(path);
      artboard.appendChild(shape);

      rootBone = file.addObject(RootBone()..length = 20);
      bone = file.addObject(Bone()..length = 20);

      rootBone.appendChild(bone);
      artboard.appendChild(rootBone);
    });
    file.captureJournalEntry();

    var tendon1 = Skin.bind(rootBone, path);
    tendon1.name = 'First';
    var tendon2 = Skin.bind(bone, path);
    tendon2.name = 'Second';
    expect(tendon1, isNotNull);
    expect(tendon2, isNotNull);

    var skins = path.children.whereType<Skin>();
    expect(skins.length, 1,
        reason: 'only one skin should\'ve been created for the path');
    var skin = skins.first;
    expect(skin.tendons.length, 2);

    file.captureJournalEntry();

    file.undo();
    expect(path.children.whereType<Skin>(), isEmpty);
    // Make sure that removing a skin doesn't cause an orphaned change that
    // lives outside of the last journal entry.
    expect(file.captureJournalEntry(), false,
        reason: 'no recorded changes should\'ve been introduced while undoing');

    // Redo should resurrect the skin and tendons, basically back to what we
    // created.
    file.redo();
    skins = path.children.whereType<Skin>();
    expect(skins.length, 1,
        reason: 'only one skin should\'ve been created for the path');
    skin = skins.first;
    expect(skin.tendons.length, 2);

    // Deleting the first tendong should keep the skin around as there's another
    // tendon still being used.
    skin.tendons.first.remove();
    file.captureJournalEntry();
    expect(skin.tendons.length, 1);

    // Deleting the last remaining tendon should kill the skin too in a single
    // journal entry.
    skin.tendons.first.remove();
    file.captureJournalEntry();
    expect(path.children.whereType<Skin>(), isEmpty);

    // Undo should re-add the removed skin and the single tendon that was
    // remaining.
    file.undo();
    skins = path.children.whereType<Skin>();
    expect(skins.length, 1, reason: 'expect our skin to come back');
    skin = skins.first;
    expect(skin.tendons.length, 1);

    file.undo();
    expect(skin.tendons.length, 2);

    // Remove both tendons in one op. Validates fix for:
    // https://github.com/rive-app/rive/issues/1248
    skin.tendons.first.remove();
    skin.tendons.first.remove();
    file.captureJournalEntry();
    // Expect the skin to have been removed by the same op since we removed both
    // tendons.
    expect(skin.isActive, false);

    file.undo();
    // Skin should be re-added.
    skins = path.children.whereType<Skin>();
    expect(skins.length, 1, reason: 'expect our skin to come back');
    skin = skins.first;
    // Both tendons come back
    expect(skin.tendons.length, 2);
    // Tendons are in order.
    expect(skin.tendons[0].name, 'First');
    expect(skin.tendons[1].name, 'Second');
  });
}
