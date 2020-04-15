import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_data/local_data.dart';
import 'package:rive_core/animation/animation.dart';
import 'package:rive_core/animation/keyed_object.dart';
import 'package:rive_core/animation/keyed_property.dart';
import 'package:rive_core/animation/keyframe_double.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/backboard.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/rive_file.dart';

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

    file.add(backboard);
    file.add(artboard);
  });
  file.captureJournalEntry();
  return file;
}

void main() {
  test('apply an animation', () {
    var file = _makeFile();

    file.batchAdd(() {
      var node = Node()
        ..name = 'Moving Node'
        ..x = 0
        ..y = 0;
      file.add(node);

      var animation = Animation()..name = 'Test Animation';
      file.add(animation);

      expect(animation.getKeyed(node), null);

      var keyedObject = animation.makeKeyed(node);

      expect(keyedObject.getKeyed(NodeBase.xPropertyKey), null);

      var keyedProperty = keyedObject.makeKeyed(NodeBase.xPropertyKey);

      // TODO: explore Core api to get these keyed dynamically.
      var keyFrame1 = KeyFrameDouble()
        ..keyedPropertyId = keyedProperty.id
        ..time = 0
        ..value = 34.0;
      var keyFrame2 = KeyFrameDouble()
        ..keyedPropertyId = keyedProperty.id
        ..time = 60
        ..value = 40.0;
      file.add(keyFrame1);
      file.add(keyFrame2);
    });
  });
}
