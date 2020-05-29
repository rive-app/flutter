import 'dart:ui';

import 'package:core/key_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_data/local_data.dart';
import 'package:rive_core/animation/linear_animation.dart';
import 'package:rive_core/animation/keyframe_double.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/backboard.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/rive_file.dart';

/// A LinearAnimation has a list of KeyedObjects. The relationship looks like
/// this:
///
// ┌───────────────┐
// │LinearAnimation│
// └───────────────┘
//         │      ┌───────────┐
//         ├─────▶│KeyedObject│
//         │      └───────────┘
//         │            │
//         │            │  ┌───────────────┐
//         │            ├─▶│ KeyedProperty │
//         │            │  └───────────────┘
//         │            │          │  ┌───────────────┐
//         │            │          ├─▶│   KeyFrame    │
//         │            │          │  └───────────────┘
//         │            │          │  ┌───────────────┐
//         │            │          ├─▶│   KeyFrame    │
//         │            │          │  └───────────────┘
//         │            │          │  ┌───────────────┐
//         │            │          └─▶│   KeyFrame    │
//         │            │             └───────────────┘
//         │            │  ┌───────────────┐
//         │            └─▶│ KeyedProperty │
//         │               └───────────────┘
//         │                       │  ┌───────────────┐
//         │                       ├─▶│   KeyFrame    │
//         │                       │  └───────────────┘
//         │                       │  ┌───────────────┐
//         │                       ├─▶│   KeyFrame    │
//         │                       │  └───────────────┘
//         │                       │  ┌───────────────┐
//         │                       └─▶│   KeyFrame    │
//         │      ┌───────────┐       └───────────────┘
//         └─────▶│KeyedObject│
//                └───────────┘
//                      │
//                      │  ┌───────────────┐
//                      ├─▶│ KeyedProperty │
//                      │  └───────────────┘
//                      │          │  ┌───────────────┐
//                      │          ├─▶│   KeyFrame    │
//                      │          │  └───────────────┘
//                      │          │  ┌───────────────┐
//                      │          ├─▶│   KeyFrame    │
//                      │          │  └───────────────┘
//                      │          │  ┌───────────────┐
//                      │          └─▶│   KeyFrame    │
//                      │             └───────────────┘
//                      │  ┌───────────────┐
//                      └─▶│ KeyedProperty │
//                         └───────────────┘
//                                 │  ┌───────────────┐
//                                 ├─▶│   KeyFrame    │
//                                 │  └───────────────┘
//                                 │  ┌───────────────┐
//                                 ├─▶│   KeyFrame    │
//                                 │  └───────────────┘
//                                 │  ┌───────────────┐
//                                 └─▶│   KeyFrame    │
//                                    └───────────────┘

RiveFile _makeFile() {
  LocalDataPlatform dataPlatform = LocalDataPlatform.make();

  final file = RiveFile(
    'fake',
    localDataPlatform: dataPlatform,
  );

  // Make a somewhat sane file.
  Artboard artboard;
  file.batchAdd(() {
    var backboard = Backboard();
    artboard = Artboard()
      ..name = 'My Artboard'
      ..x = 0
      ..y = 0
      ..width = 1920
      ..height = 1080;

    file.addObject(backboard);
    file.addObject(artboard);
  });
  file.captureJournalEntry();
  return file;
}

void main() {
  test('apply an animation', () {
    var file = _makeFile();

    Artboard artboard;
    LinearAnimation animation;
    Node node;
    KeyFrameDouble kf1, kf2;
    file.batchAdd(() {
      artboard = file.addObject(Artboard());
      node = file.addObject(Node()
        ..name = 'Moving Node'
        ..x = 0
        ..y = 0);

      artboard.appendChild(node);

      animation = LinearAnimation()
        ..name = 'Test Animation'
        ..fps = 60;
      file.addObject(animation);

      expect(animation.getKeyed(node), null);

      var keyedObject = animation.makeKeyed(node);

      expect(keyedObject.getKeyed(NodeBase.xPropertyKey), null);

      var keyedProperty = keyedObject.makeKeyed(NodeBase.xPropertyKey);

      expect(keyedObject.getKeyed(NodeBase.xPropertyKey), keyedProperty);

      kf1 = node.addKeyFrame(animation, NodeBase.xPropertyKey, 0)..value = 34;
      expect(kf1.frame, 0, reason: 'frame value should be 0');

      kf2 = node.addKeyFrame(animation, NodeBase.xPropertyKey, 60)..value = 40;
      expect(kf2.frame, 60, reason: 'frame value should be 60');
    });
    expect(file.captureJournalEntry(), true,
        reason: 'animation creation should capture an entry');

    expect(kf1.seconds, 0, reason: 'seconds should have resolved to 0');
    expect(kf2.seconds, 1, reason: 'seconds should have resolved to 1');

    // start animation
    file.startAnimating();
    animation.apply(0.5);
    expect(node.x, lerpDouble(34, 40, 0.5));
    expect(node.xAnimated, lerpDouble(34, 40, 0.5));
    expect(node.xKeyState, KeyState.interpolated);

    expect(file.captureJournalEntry(), false,
        reason: 'there should be no changes after animation is complete');

    kf1.frame = 6;
    kf1.value = -14;
    file.captureJournalEntry();
    expect(kf1.seconds, 0.1, reason: 'seconds should have resolved to 0.1');

    file.resetAnimation();
    expect(node.xAnimated, null);
    expect(node.xKeyState, KeyState.none);
    animation.apply(0.5);
    expect(node.x, 10);

    // Expect undo to work with animations too.
    file.undo();
    expect(kf1.seconds, 0, reason: 'seconds should have resolved to 0');
  });
}
