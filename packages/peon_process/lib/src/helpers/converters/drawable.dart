import 'package:core/core.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/drawable.dart';
import 'package:rive_core/rive_file.dart';

import 'node.dart';

abstract class DrawableConverter extends NodeConverter {
  DrawableConverter(
    DrawableBase drawable,
    RiveFile file,
    ContainerComponent maybeParent,
  ) : super(drawable, file, maybeParent);

  @override
  void deserialize(Map<String, Object> jsonData) {
    super.deserialize(jsonData);

    final drawOrder = jsonData['drawOrder'];
    final blendMode = jsonData['blendMode'];

    final drawable = component as DrawableBase;

    if (drawOrder is int) {
      // Flare drawOrder starts at 0 and grows idefinetely, with smaller 
      // drawOrder values that are stored in the 'back', and higher drawOrder
      // values in the 'front'.
      // We use the progression: n/(n + 1), knowing that
      // n/(n + 1) < (n + 1) / (n + 2), ∀ n > 0
      // https://bit.ly/3jD3xCm
      drawable.drawOrder = FractionalIndex(drawOrder, drawOrder + 1);
    }

    if (blendMode is String) {
      drawable.blendModeValue = _blendModeFrom(blendMode);
    }
  }

  int _blendModeFrom(String blendMode) {
    switch (blendMode) {
      case "clear":
        return 0;
      case "src":
        return 1;
      case "dst":
        return 2;
      case "srcOver":
        return 3;
      case "dstOver":
        return 4;
      case "srcIn":
        return 5;
      case "dstIn":
        return 6;
      case "srcOut":
        return 7;
      case "dstOut":
        return 8;
      case "srcATop":
        return 9;
      case "dstATop":
        return 10;
      case "xor":
        return 11;
      case "plus":
        return 12;
      case "modulate":
        return 13;
      case "screen":
        return 14;
      case "overlay":
        return 15;
      case "darken":
        return 16;
      case "lighten":
        return 17;
      case "colorDodge":
        return 18;
      case "colorBurn":
        return 19;
      case "hardLight":
        return 20;
      case "softLight":
        return 21;
      case "difference":
        return 22;
      case "exclusion":
        return 23;
      case "multiply":
        return 24;
      case "hue":
        return 25;
      case "saturation":
        return 26;
      case "color":
        return 27;
      case "luminosity":
        return 28;
      default:
        return 3;
    }
  }
}
