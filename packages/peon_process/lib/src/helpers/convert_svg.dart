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
  var clippingRefs = <String, ClippingReference>{};
  var maskingRefs = <String, MaskingReference>{};
  var clips = <Node, ClipApplication>{};
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
      clippingRefs[clipPath.id] = ClippingReference(
        clipPath,
        root,
        file,
        artboard,
      );
    }
    for (var i = root.children.length - 1; i >= 0; i--) {
      addChild(
        root,
        file,
        artboard,
        root.children[i],
        clippingRefs,
        maskingRefs,
        clips,
      );
    }

    for (var i = root.masks.length - 1; i >= 0; i--) {
      var mask = MaskingReference(
        root.masks[i] as DrawableGroup,
        root,
        file,
        artboard,
      );
      maskingRefs['url(#${mask.name})'] = mask;
    }
  });

  file.batchAdd(() {
    clips.forEach((key, value) {
      if (clippingRefs.containsKey(value.clipAttr)) {
        var clipShape = getClippingShape(
            key,
            value.offset,
            clippingRefs[value.clipAttr].clipPath,
            clippingRefs[value.clipAttr].root,
            clippingRefs[value.clipAttr].file,
            clippingRefs[value.clipAttr].parent,
            clippingRefs,
            maskingRefs,
            clips);
        clip(key, clipShape, file);
      }
      if (maskingRefs.containsKey(value.clipAttr)) {
        var maskShape = getMaskingShape(
            key,
            value.offset,
            maskingRefs[value.clipAttr].mask,
            maskingRefs[value.clipAttr].root,
            maskingRefs[value.clipAttr].file,
            maskingRefs[value.clipAttr].parent,
            clippingRefs,
            maskingRefs,
            clips);

        clip(key, maskShape, file);
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
