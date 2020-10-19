import 'package:flutter_svg/flutter_svg.dart';
import 'package:peon_process/src/helpers/svg_utils/clipping.dart';
import 'package:peon_process/src/helpers/svg_utils/masking.dart';
import 'package:peon_process/src/helpers/svg_utils/node.dart';
import 'package:peon_process/src/helpers/svg_utils/utils.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/backboard.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/rive_file.dart';

void addArtboard(RiveFile file, DrawableRoot root) {
  Backboard backboard;
  Artboard artboard;
  var clippingRefs = <String, Node>{};
  var clips = <Node, String>{};
  file.batchAdd(() {
    backboard = Backboard();
    artboard = Artboard()
      ..x = 0
      ..y = 0
      ..originX = 0
      ..originY = 0
      ..width = root.viewport.viewBox.width
      ..height = root.viewport.viewBox.height;

    file.addObject(backboard);
    file.addObject(artboard);
  });

  file.batchAdd(() {
    for (var i = root.clipPaths.length - 1; i >= 0; i--) {
      var clipPath = root.clipPaths[i];
      clippingRefs[clipPath.id] = getClippingShape(
        clipPath,
        root,
        file,
        artboard,
        clippingRefs,
        clips,
      );
    }
    for (var i = root.children.length - 1; i >= 0; i--) {
      addChild(root, file, artboard, root.children[i], clippingRefs, clips);
    }

    for (var i = root.masks.length - 1; i >= 0; i--) {
      var mask = getMaskingShape(
        root.masks[i] as DrawableGroup,
        root,
        file,
        artboard,
        clippingRefs,
        clips,
      );
      clippingRefs['url(#${mask.name})'] = mask;
    }
    clips.forEach((key, value) {
      if (clippingRefs.containsKey(value)) {
        clip(key, clippingRefs[value], file);
      }
    });
  });
}

RiveFile createFromSvg(DrawableRoot svgDrawable) {
  // LocalDataPlatform dataPlatform = LocalDataPlatform.make();

  var riveFile = RiveFile(
      attrOrDefault(svgDrawable.attributes, 'id', 'FileName'),
      localDataPlatform: null);
  addArtboard(riveFile, svgDrawable);
  return riveFile;
}
