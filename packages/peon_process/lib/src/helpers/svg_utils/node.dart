import 'package:flutter_svg/flutter_svg.dart';
import 'package:peon_process/src/helpers/svg_utils/clipping.dart';
import 'package:peon_process/src/helpers/svg_utils/gradient.dart';
import 'package:peon_process/src/helpers/svg_utils/masking.dart';
// import 'package:peon_process/src/helpers/svg_utils/masking.dart';
import 'package:peon_process/src/helpers/svg_utils/paths.dart';
import 'package:peon_process/src/helpers/svg_utils/utils.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/transform_components.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/shapes/clipping_shape.dart';
import 'package:rive_core/shapes/path_composer.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:xml/xml_events.dart';

void addChild(
  DrawableRoot root,
  RiveFile file,
  ContainerComponent parent,
  Drawable drawable,
  Map<String, Node> clippingRefs,
  Map<Node, String> clips, {
  bool forceNode = false,
  bool mask = false,
}) {
  switch (drawable.runtimeType) {
    case DrawableShape:
      var drawableShape = drawable as DrawableShape;
      Node node;
      if (forceNode) {
        node = Node();
      } else {
        node = Shape();
      }
      var id = attrOrDefault(drawableShape.attributes, 'id', null);
      node.name = id;

      var shapeOffset = getShapeOffset(file, drawableShape.path as RivePath);
      node.x = shapeOffset.dx;
      node.y = shapeOffset.dy;
      // we do not do this here, as the color already contains this?
      // ..opacity = drawableShape.style.groupOpacity;

      var composer = PathComposer();
      file.addObject(composer);
      file.addObject(node);
      node.appendChild(composer);

      var nodeParent = parent;

      if (drawableShape.transform != null) {
        var shapeTransform = Mat2D.fromMat4(drawableShape.transform);
        var pathTranslation = Mat2D.fromTranslation(
            Vec2D.fromValues(shapeOffset.dx, shapeOffset.dy));
        var appliedTransform = Mat2D();
        Mat2D.multiply(
          appliedTransform,
          shapeTransform,
          pathTranslation,
        );

        // need to unpack the transform into rotation, scale and transform
        var transform = TransformComponents();
        Mat2D.decompose(appliedTransform, transform);

        node.x = transform.x;
        node.y = transform.y;
        node.rotation += transform.rotation;
        node.scaleX *= transform.scaleX;
        node.scaleY *= transform.scaleY;
      }
      nodeParent.appendChild(node);

      var paths = getPaths(file, drawableShape.path as RivePath, shapeOffset);
      paths.forEach((path) {
        node.appendChild(path);
      });
      if (!mask && node is Shape && drawableShape.style != null) {
        if (drawableShape.style.fill != null &&
            drawableShape.style.fill.color != null) {
          var fill = node.createFill(drawableShape.style.fill.color);
          if (drawableShape.style.blendMode != null) {
            fill.blendMode = drawableShape.style.blendMode;
            node.blendMode = drawableShape.style.blendMode;
          }
          if (drawableShape.style.fill.shader != null) {
            // we *should* have a gradient
            var gradientRef = drawableShape.attributes
                .firstWhere((element) => element.name == 'fill')
                .value;

            addGradient(
              root.definitions.getGradient(gradientRef),
              file,
              fill,
              drawableShape.bounds,
              shapeOffset,
            );
          }
        }
        if (drawableShape.style.stroke != null &&
            drawableShape.style.stroke.color != null) {
          var stroke = node.createStroke(drawableShape.style.stroke.color);
          stroke.thickness = drawableShape.style.stroke.strokeWidth;
          stroke.strokeCap = drawableShape.style.stroke.strokeCap;
          stroke.strokeJoin = drawableShape.style.stroke.strokeJoin;

          if (drawableShape.style.blendMode != null) {
            stroke.blendMode = drawableShape.style.blendMode;
            node.blendMode = drawableShape.style.blendMode;
          }
        }
      }

      registerClips(
        drawableShape,
        drawableShape.attributes,
        node,
        clips,
      );

      break;
    case DrawableGroup:
      var drawableGroup = drawable as DrawableGroup;
      var id = attrOrDefault(drawableGroup.attributes, 'id', null);
      var node = Node()
        ..name = id
        ..x = 0
        ..y = 0;

      // note: we REALLY dont want opacity to be null
      if (drawableGroup.style.groupOpacity != null) {
        node.opacity = drawableGroup.style.groupOpacity;
      }
      if (drawableGroup.style.fill != null &&
          drawableGroup.style.fill.color != null &&
          drawableGroup.style.fill.color.alpha != 255) {
        node.opacity = drawableGroup.style.fill.color.alpha / 255;
      }

      if (drawableGroup.transform != null) {
        // need to unpack the transform into rotation, scale and transform
        var transform = TransformComponents();
        Mat2D.decompose(Mat2D.fromMat4(drawableGroup.transform), transform);
        node.rotation += transform.rotation;
        node.x += transform.x;
        node.y += transform.y;
        node.scaleX *= transform.scaleX;
        node.scaleY *= transform.scaleY;
      }

      file.addObject(node);
      parent.appendChild(node);

      registerClips(
        drawableGroup,
        drawableGroup.attributes,
        node,
        clips,
      );

      for (var i = drawableGroup.clipPaths.length - 1; i >= 0; i--) {
        var clipPath = drawableGroup.clipPaths[i];
        clippingRefs[clipPath.id] = getClippingShape(
          clipPath,
          root,
          file,
          node,
          clippingRefs,
          clips,
        );
      }

      for (var i = drawableGroup.children.length - 1; i >= 0; i--) {
        addChild(
          root,
          file,
          node,
          drawableGroup.children[i],
          clippingRefs,
          clips,
          mask: mask,
        );
      }

      for (var i = 0; i < drawableGroup.masks.length; i++) {
        var mask = getMaskingShape(
          drawableGroup.masks[i] as DrawableGroup,
          root,
          file,
          node,
          clippingRefs,
          clips,
        );
        clippingRefs['url(#${mask.name})'] = mask;
      }

      break;
    default:
      print('no idea what to do with $drawable');
  }
}

void registerClips(
  DrawableStyleable drawable,
  List<XmlEventAttribute> attributes,
  Node node,
  Map<Node, String> clips,
) {
  if (drawable.style.clipPath != null) {
    var clipAttr = attributes
        .firstWhere((element) =>
            element.name == 'clip-path' || element.value.contains('clip-path'))
        .value;
    clipAttr = clipAttr.split(':').last;
    clips[node] = clipAttr;
  }
  if (drawable.style.mask != null) {
    var clipAttr = attributes
        .firstWhere((element) =>
            element.name == 'mask' || element.value.contains('mask'))
        .value;
    clipAttr = clipAttr.split(':').last;
    clips[node] = clipAttr;
  }
}

void clip(Node clipped, Node clipSource, RiveFile file) {
  var clipper = ClippingShape();
  file.addObject(clipper);
  clipper.source = clipSource;
  clipped.appendChild(clipper);
}
