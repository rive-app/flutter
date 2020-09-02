import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:local_data/local_data.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/bones/bone.dart';
import 'package:rive_core/bones/root_bone.dart';

import 'src/test_rive_file.dart';

void main() {
  final dataPlatform = LocalDataPlatform.make();
  TestRiveFile file;

  setUp(() {
    // Connect a fake coop client
    file = TestRiveFile(
      'fake',
      localDataPlatform: dataPlatform,
      overridePreferences: <String, dynamic>{
        'token': 'fake',
        'clientId': 1,
      },
      useSharedPreferences: false,
    );
  });

  test('bones can be created', () {
    Artboard artboard;
    RootBone rootBone;
    Bone bone;

    file.batchAdd(() {
      artboard = file.addObject(Artboard());
      rootBone = file.addObject(RootBone()..length = 50);
      bone = file.addObject(Bone()..length = 40);
      rootBone.appendChild(bone);
      artboard.appendChild(rootBone);
    });

    expect(artboard.children.length, 1);
    expect(rootBone.children.length, 1);
    expect(bone.children.isEmpty, true);
  });

  test('bones can be undone and redone', () {
    Artboard artboard;
    RootBone rootBone;
    Bone bone;

    file.batchAdd(() {
      artboard = file.addObject(Artboard());
    });
    file.captureJournalEntry();

    file.batchAdd(() {
      rootBone = file.addObject(RootBone()..length = 50);
      artboard.appendChild(rootBone);
    });
    file.captureJournalEntry();

    file.batchAdd(() {
      bone = file.addObject(Bone()..length = 40);
      rootBone.appendChild(bone);
    });
    file.captureJournalEntry();

    expect(artboard.children.length, 1);
    expect(rootBone.children.length, 1);
    expect(bone.children.isEmpty, true);

    file.undo();

    expect(artboard.children.length, 1);
    expect(rootBone.children.length, isZero);

    file.undo();

    expect(artboard.children.length, isZero);

    file.redo();

    expect(artboard.children.length, 1);
    // a new root bone will be created, so check that one
    expect(artboard.children.first is RootBone, true);
    expect((artboard.children.first as RootBone).children.length, isZero);

    file.redo();

    expect(artboard.children.length, 1);
    expect(artboard.children.first is RootBone, true);
    expect((artboard.children.first as RootBone).children.length, 1);
    expect((artboard.children.first as RootBone).children.first is Bone, true);
    expect(
        ((artboard.children.first as RootBone).children.first as Bone)
            .children
            .length,
        isZero);
  });

  test('bones translate child bones correctly', () {
    Artboard artboard;
    RootBone rootBone;
    Bone firstBone, secondBone;

    file.batchAdd(() {
      artboard = file.addObject(Artboard());
      rootBone = file.addObject(RootBone()..length = 50);
      firstBone = file.addObject(Bone()..length = 40);
      secondBone = file.addObject(Bone()..length = 30);
      firstBone.appendChild(secondBone);
      rootBone.appendChild(firstBone);
      artboard.appendChild(rootBone);
    });
    file.captureJournalEntry();

    expect(artboard.children.length, 1);
    expect(rootBone.children.length, 1);
    expect(firstBone.children.length, 1);
    expect(secondBone.children.isEmpty, true);

    expect(rootBone.x, isZero);
    expect(rootBone.y, isZero);
    expect(rootBone.rotation, isZero);
    expect(rootBone.length, 50);

    // the first bone's length is the root bone's length
    expect(firstBone.x, 50);
    expect(firstBone.y, isZero);
    expect(firstBone.length, 40);

    // the second bone's length is the first bone's length
    expect(secondBone.x, 40);
    expect(secondBone.y, isZero);
    expect(secondBone.length, 30);

    // translate the root bone
    rootBone.xCore = 10;
    expect(rootBone.x, 10);
    // Note that the x of bones doesn't change
    expect(firstBone.x, 50);
    expect(secondBone.x, 40);

    // lengthen the root bone
    rootBone.lengthCore += 10;
    expect(rootBone.length, 60);
    // Note that the x of bones are updated by the length change
    expect(firstBone.x, 60);
    expect(secondBone.x, 40);
    // Note that their length doesn't change
    expect(firstBone.length, 40);
    expect(secondBone.length, 30);

    // rotate the root bone
    rootBone.rotationCore = math.pi;
    expect(rootBone.rotation, math.pi);
    // Note that the rotation of the child bones remain the same
    expect(firstBone.rotation, 0);
    expect(secondBone.rotation, 0);
    // Note that the bone's x and length remain the same
    expect(firstBone.length, 40);
    expect(secondBone.length, 30);
    expect(firstBone.x, 60);
    expect(secondBone.x, 40);
    expect(firstBone.y, 0);
    expect(secondBone.y, 0);
  });
}
