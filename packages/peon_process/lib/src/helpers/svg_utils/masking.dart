import 'dart:ui';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:peon_process/src/helpers/svg_utils/clipping.dart';
import 'package:peon_process/src/helpers/svg_utils/node.dart';
import 'package:peon_process/src/helpers/svg_utils/utils.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/transform_components.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/shapes/path_composer.dart';

class MaskingReference {
  final DrawableGroup mask;
  final DrawableRoot root;
  final RiveFile file;
  final ContainerComponent parent;

  MaskingReference(this.mask, this.root, this.file, this.parent);

  String get name => attrOrDefault(mask.attributes, 'id', null);
}

Node getMaskingShape(
  Node target,
  Offset offset,
  DrawableGroup mask,
  DrawableRoot root,
  RiveFile file,
  ContainerComponent parent,
  Map<String, ClippingReference> clippingRefs,
  Map<String, MaskingReference> maskingRefs,
  Map<Node, ClipApplication> clips,
) {
  var id = attrOrDefault(mask.attributes, 'id', null);
  var maskShape = Node()
    ..name = id
    ..x = 0
    ..y = 0;

  var composer = PathComposer();
  file.addObject(composer);
  file.addObject(maskShape);
  maskShape.appendChild(composer);

  parent.appendChild(maskShape);

  var clipTransform =
      (mask.transform == null) ? Mat2D() : Mat2D.fromMat4(mask.transform);
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

  maskShape.rotation += transform.rotation;
  maskShape.x += transform.x;
  maskShape.y += transform.y;
  maskShape.scaleX *= transform.scaleX;
  maskShape.scaleY *= transform.scaleY;

  mask.children.forEach((child) {
    addChild(
      root,
      file,
      maskShape,
      child,
      clippingRefs,
      maskingRefs,
      clips,
      forceNode: true,
      mask: true,
    );
  });
  return maskShape;
}
