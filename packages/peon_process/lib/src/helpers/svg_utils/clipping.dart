import 'package:flutter_svg/flutter_svg.dart';
import 'package:peon_process/src/helpers/svg_utils/node.dart';

import 'package:rive_core/container_component.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/transform_components.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/shapes/path_composer.dart';
import 'package:rive_core/shapes/shape.dart';

Shape getClippingShape(
  ClipPath clipPath,
  DrawableRoot root,
  RiveFile file,
  ContainerComponent parent,
  Drawable drawable,
  Map<String, Node> clippingRefs,
) {
  var clipShape = Shape()
    ..name = clipPath.id
    ..x = 0
    ..y = 0;

  var composer = PathComposer();
  file.addObject(composer);
  file.addObject(clipShape);
  clipShape.appendChild(composer);

  // Note: Clip Paths are extracted by our svg parser, and plucked out of the
  //        svg hierarchy, we re-attach them to the main artboard, but we
  //        may want to see about putting them back into their proper place
  file.artboards.first.appendChild(clipShape);

  if (clipPath.transform != null) {
    // need to unpack the transform into rotation, scale and transform
    var transform = TransformComponents();
    Mat2D.decompose(Mat2D.fromMat4(clipPath.transform), transform);
    clipShape.rotation += transform.rotation;
    clipShape.x += transform.x;
    clipShape.y += transform.y;
    clipShape.scaleX *= transform.scaleX;
    clipShape.scaleY *= transform.scaleY;
  }

  clipPath.shapes.forEach((shape) {
    addChild(
      root,
      file,
      clipShape,
      shape,
      clippingRefs,
      forceNode: true,
    );
  });
  return clipShape;
}
