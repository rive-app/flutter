import 'dart:ui';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:peon_process/src/helpers/svg_utils/masking.dart';
import 'package:peon_process/src/helpers/svg_utils/node.dart';

import 'package:rive_core/container_component.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/transform_components.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/shapes/path_composer.dart';
import 'package:rive_core/shapes/shape.dart';

class ClippingReference {
  final ClipPath clipPath;
  final DrawableRoot root;
  final RiveFile file;
  final ContainerComponent parent;

  ClippingReference(this.clipPath, this.root, this.file, this.parent);
}

Shape getClippingShape(
  Node target,
  Offset offset,
  ClipPath clipPath,
  DrawableRoot root,
  RiveFile file,
  ContainerComponent parent,
  Map<String, ClippingReference> clippingRefs,
  Map<String, MaskingReference> maskingRefs,
  Map<Node, ClipApplication> clips,
) {
  var clipShape = Shape()
    ..name = clipPath.id
    ..x = 0
    ..y = 0;

  var composer = PathComposer();
  file.addObject(composer);
  file.addObject(clipShape);
  clipShape.appendChild(composer);

  parent.appendChild(clipShape);

  var clipTransform = (clipPath.transform == null)
      ? Mat2D()
      : Mat2D.fromMat4(clipPath.transform);
  var shapeTransform =
      (target.worldTransform == null) ? Mat2D() : target.worldTransform;

  target.calculateWorldTransform();
  var appliedTransform = Mat2D();

  Mat2D.multiply(
    appliedTransform,
    clipTransform,
    Mat2D.fromTranslation(Vec2D.fromValues(-offset.dx, -offset.dy)),
  );
  Mat2D.multiply(
    appliedTransform,
    shapeTransform,
    appliedTransform,
  );
  var transform = TransformComponents();
  Mat2D.decompose(appliedTransform, transform);
  // need to unpack the transform into rotation, scale and transform

  clipShape.rotation += transform.rotation;
  clipShape.x += transform.x;
  clipShape.y += transform.y;
  clipShape.scaleX *= transform.scaleX;
  clipShape.scaleY *= transform.scaleY;

  clipPath.shapes.forEach((shape) {
    addChild(
      root,
      file,
      clipShape,
      shape,
      clippingRefs,
      maskingRefs,
      clips,
      forceNode: true,
    );
  });
  return clipShape;
}
