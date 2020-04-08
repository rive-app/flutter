import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/node.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/transformers/stage_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transforming_tool.dart';
import 'package:utilities/iterable.dart';

/// Transformer that translates [StageItem]'s with underlying [Node] components.
class NodeTranslateTransformer extends StageTransformer {
  Iterable<Node> _nodes;

  @override
  void advance(DragTransformDetails details) {
    Map<Node, Mat2D> worldToParents = {};

    var failedInversion = Mat2D();

    for (final node in _nodes) {

      // First assume we can use artboard level mouse move.
      var delta = details.artboardWorld.delta;

      // If it's a node, we have to get into its parent's space as that's where
      // its translation lives.
      if (node.parent is Node) {
        var parentNode = node.parent as Node;
        var parentWorldInverse = worldToParents[parentNode];
        if (parentWorldInverse == null) {
          Mat2D inverse = Mat2D();
          if (!Mat2D.invert(inverse, parentNode.worldTransform)) {
            // If the inversion fails (0 scale?) then set the inverse as a
            // failed inversion so we don't attempt to re-process it.
            worldToParents[parentNode] = failedInversion;
          } else {
            worldToParents[parentNode] = inverse;
          }
        }

        // Only process items with valid transform spaces.
        if (parentWorldInverse == null ||
            parentWorldInverse == failedInversion) {
          continue;
        }
        delta = Vec2D.transformMat2(Vec2D(), delta, parentWorldInverse);
      }

      // Finally apply the delta (or transformed delta).
      node.x += delta[0];
      node.y += delta[1];
    }
  }

  @override
  void complete() {}

  @override
  bool init(Set<StageItem> items, DragTransformDetails details) {
    _nodes = items.mapWhereType<Node>((element) => element.component);
    return _nodes.isNotEmpty;
  }
}
