import 'dart:math';

import 'package:peon_process/converters.dart';
import 'package:rive_core/bones/bone.dart';
import 'package:rive_core/bones/root_bone.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/transform_component.dart';

abstract class TransformComponentConverter extends ComponentConverter {
  final List<int> clips = [];

  TransformComponentConverter(
    TransformComponent component,
    RiveFile context,
    ContainerComponent maybeParent,
  ) : super(component, context, maybeParent);

  @override
  void deserialize(Map<String, Object> jsonData) {
    super.deserialize(jsonData);
    final translation = jsonData['translation'];
    final rotation = jsonData['rotation'];
    final scale = jsonData['scale'];
    final opacity = jsonData['opacity'];
    // TODO:
    final displayType = jsonData['displayType'];
    final clipIds = jsonData['clips'];
    final clipsOptions = jsonData['clipsOptions'];
    // TODO: render opacity?

    // print('Node');
    // print('Translation: $translation');
    // print('Scale: $scale');
    // print('Opacity: $opacity');

    final transformComponent = component as TransformComponent;

    // RootBones can set their translation, but normal bones can't, as it is
    // implied by the (transform + length) of the previous bone in the chain.
    final isBone = component is Bone && !(component is RootBone);
    if (translation is List && !isBone) {
      transformComponent
        ..x = (translation[0] as num).toDouble()
        ..y = (translation[1] as num).toDouble();
    }

    if (rotation is num) {
      transformComponent.rotation = rotation.toDouble() * pi / 180;
    }

    if (scale is List) {
      transformComponent
        ..scaleX = (scale[0] as num).toDouble()
        ..scaleY = (scale[1] as num).toDouble();
    }

    if (opacity is num) {
      transformComponent.opacity = opacity.toDouble();
    }

    if (clipIds is List) {
      for (final c in clipIds) {
        if (c is Map) {
          final clipId = c['id'] as int;
          clips.add(clipId);
        } else if (c is int) {
          clips.add(c);
        }
      }
    }
  }
}
