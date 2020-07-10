import 'dart:math';
import 'dart:ui';

import 'package:utilities/deserialize.dart';
import 'package:local_data/local_data.dart';
import 'package:rive_core/animation/keyframe_double.dart';
import 'package:rive_core/animation/linear_animation.dart';
import 'package:rive_core/animation/loop.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/backboard.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/runtime/runtime_exporter.dart';
import 'package:rive_core/runtime/runtime_header.dart';
import 'package:rive_core/shapes/paint/fill.dart';
import 'package:rive_core/shapes/paint/solid_color.dart';
import 'package:rive_core/shapes/rectangle.dart';
import 'package:rive_core/shapes/shape.dart';

class IllegalTask implements Exception {
  String issue;
  IllegalTask(this.issue);
}

abstract class Task {
  static Task fromData(Map<String, dynamic> data) {
    if (!data.containsKey("action")) {
      throw IllegalTask(
          "Expecting a JSON structure with `action` but got $data");
    }
    switch ((data["action"] as String).toLowerCase()) {
      case 'ping':
        return PingTask();
      case 'echo':
        return EchoTask.fromData(data);
      case 'makefile':
        return MakeFileTask();
      default:
        throw Exception('Unknown action $data');
    }
  }

  bool execute();
}

class PingTask extends Task {
  @override
  bool execute() {
    print('pinged');
    return true;
  }
}

class EchoTask extends Task {
  final String message;
  EchoTask({this.message});

  factory EchoTask.fromData(Map<String, dynamic> data) {
    if (!data.containsKey("params")) {
      throw IllegalTask(
          "Expecting a JSON structure with `params` but got $data");
    }

    var params = data.getMap<String, Object>('params');
    return EchoTask(message: params.getString('message'));
  }
  @override
  bool execute() {
    print(message);
    return true;
  }
}

class MakeFileTask extends Task {
  @override
  bool execute() {
    RiveFile exportFrom;
    Backboard backboard;
    Artboard artboard;
    LocalDataPlatform dataPlatform = LocalDataPlatform.make();

    exportFrom = RiveFile(
      'fake',
      localDataPlatform: dataPlatform,
    );

    // Make a somewhat sane file.
    exportFrom.batchAdd(() {
      backboard = Backboard();
      artboard = Artboard()
        ..name = 'My Artboard'
        ..x = 0
        ..y = 0
        ..width = 1920
        ..height = 1080;

      exportFrom.addObject(backboard);
      exportFrom.addObject(artboard);

      // Add solid color fill to artboard.
      var solidColor = SolidColor()..colorValue = 0xFF313131;
      var fill = Fill()..name = 'Background';
      exportFrom.addObject(fill);
      exportFrom.addObject(solidColor);
      artboard.appendChild(fill);
      fill.appendChild(solidColor);
    });
    exportFrom.captureJournalEntry();
    Node a;
    Shape shape;
    Rectangle path;
    exportFrom.batchAdd(() {
      a = Node()
        ..name = 'A'
        ..x = 960
        ..y = 540;
      exportFrom.addObject(a);
      artboard.appendChild(a);

      shape = Shape()
        ..name = 'Rectangle Shape'
        ..x = 0
        ..y = 0;
      exportFrom.addObject(shape);
      a.appendChild(shape);

      path = Rectangle()
        ..name = 'Rectangle Path'
        ..x = 0
        ..y = 0
        ..width = 256
        ..height = 256;
      exportFrom.addObject(path);
      shape.appendChild(path);

      const fillColor = Color(0xFF00FF00);
      shape.createFill(fillColor);

      // Make the rectangle spin (let's just animate the node that contains it).
      var animation = LinearAnimation()
        ..name = 'Spin'
        ..fps = 60
        ..loop = Loop.pingPong
        ..artboardId = artboard.id;
      exportFrom.addObject(animation);

      var keyedObject = animation.makeKeyed(a);

      // Start keying rotation
      keyedObject.makeKeyed(NodeBase.rotationPropertyKey);

      // Add keyframe at 0 frames with value of 0
      a
          .addKeyFrame<KeyFrameDouble>(
              animation, NodeBase.rotationPropertyKey, 0)
          .value = 0;
      // Add keyframe at 60 frames (1 second) with value of 2 pi (360)
      a
          .addKeyFrame<KeyFrameDouble>(
              animation, NodeBase.rotationPropertyKey, 60)
          .value = 2 * pi;

      exportFrom.captureJournalEntry();
    });

    var exporter = RuntimeExporter(
      core: exportFrom,
      info: RuntimeHeader(ownerId: 1, fileId: 1),
    );
    var bytes = exporter.export();

    // var file = File('rectangle.riv');
    // file.create(recursive: true);
    // file.writeAsBytesSync(bytes, flush: true);
    print('Created file:');
    print(bytes);
    return true;
  }
}
