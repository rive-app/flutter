import 'dart:math';

import 'package:peon_process/converters.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/rive_file.dart';

class NodeConverter extends ComponentConverter {
  NodeConverter(
    NodeBase node,
    RiveFile file,
    ContainerComponent maybeParent,
  ) : super(node, file, maybeParent);

  @override
  void deserialize(Map<String, Object> jsonData) {
    super.deserialize(jsonData);
    final translation = jsonData['translation'];
    final rotation = jsonData['rotation'];
    final scale = jsonData['scale'];
    final opacity = jsonData['opacity'];
    final displayType = jsonData['displayType'];
    final clips = jsonData['clips'];
    final clipsOptions = jsonData['clipsOptions'];

    // print('Node: $jsonData');
    print('Node');
    print('Translation: $translation');
    print('Scale: $scale');
    print('Opacity: $opacity');

    final node = component as Node;

    if (translation is List) {
      node
        ..x = (translation[0] as num).toDouble()
        ..y = (translation[1] as num).toDouble();
    }

    if (rotation is num) {
      node.rotation = rotation.toDouble() * pi / 180;
    }

    if (scale is List) {
      node
        ..scaleX = (scale[0] as num).toDouble()
        ..scaleY = (scale[1] as num).toDouble();
    }

    if (opacity is num) {
      node.opacity = opacity.toDouble();
    }
  }
}
