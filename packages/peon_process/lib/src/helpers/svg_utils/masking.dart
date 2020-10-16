import 'package:flutter_svg/flutter_svg.dart';
import 'package:peon_process/src/helpers/svg_utils/node.dart';
import 'package:peon_process/src/helpers/svg_utils/utils.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/transform_components.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/shapes/path_composer.dart';

Node getMaskingShape(
  DrawableGroup mask,
  DrawableRoot root,
  RiveFile file,
  ContainerComponent parent,
  Map<String, Node> clippingRefs,
  Map<Node, String> clips,
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

  if (mask.transform != null) {
    // need to unpack the transform into rotation, scale and transform
    var transform = TransformComponents();
    Mat2D.decompose(Mat2D.fromMat4(mask.transform), transform);
    maskShape.rotation += transform.rotation;
    maskShape.x += transform.x;
    maskShape.y += transform.y;
    maskShape.scaleX *= transform.scaleX;
    maskShape.scaleY *= transform.scaleY;
  }

  mask.children.forEach((child) {
    addChild(
      root,
      file,
      maskShape,
      child,
      clippingRefs,
      clips,
      forceNode: true,
      mask: true,
    );
  });
  return maskShape;
}
