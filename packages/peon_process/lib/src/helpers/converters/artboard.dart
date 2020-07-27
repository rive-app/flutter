import 'dart:ui';

import 'package:rive_core/artboard.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/rive_file.dart';

import 'component.dart';

class ArtboardConverter extends ComponentConverter {
  ArtboardConverter(
    ArtboardBase artboard,
    RiveFile file,
    ContainerComponent maybeParent,
  ) : super(artboard, file, maybeParent);

  @override
  void deserialize(Map<String, Object> jsonData) {
    super.deserialize(jsonData);
    final width = jsonData['width'];
    final height = jsonData['height'];
    final translation = jsonData['translation'];
    final origin = jsonData['origin'];
    final color = jsonData['color'];
    final shouldClip = jsonData['clipContents'];

    final artboard = component as Artboard;

    if (width is num) {
      artboard.width = width.toDouble();
    }
    if (height is num) {
      artboard.height = height.toDouble();
    }
    if (translation is List) {
      artboard
        ..x = (translation[0] as num).toDouble()
        ..y = (translation[1] as num).toDouble();
    }

    if (origin is List) {
      artboard
        ..originX = (origin[0] as num).toDouble()
        ..originY = (origin[1] as num).toDouble();
    }

    // Artboard background can only be a solid fill.
    if (color is List) {
      assert(color.every((Object e) => e is num));

      final colorValue = Color.fromRGBO(
        ((color[0] as num) * 255).toInt(),
        ((color[1] as num) * 255).toInt(),
        ((color[2] as num) * 255).toInt(),
        (color[3] as num).toDouble(),
      );
      artboard.createFill(colorValue);
    }
  }
}
