import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/node.dart';
import 'package:rive_editor/rive/stage/items/stage_vertex.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/transformers/stage_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transforming_tool.dart';

/// Transformer that translates [StageItem]'s with underlying [Node] components.
class VertexTranslateTransformer extends StageTransformer {
  Iterable<StageVertex> _stageVertices;

  @override
  void advance(DragTransformDetails details) {
    for (final stageVertex in _stageVertices) {
      // First assume we can use artboard level mouse move.
      var delta = details.artboardWorld.delta;

      var vertex = stageVertex.component;
      // Get into world...
      var worldTranslation = Vec2D.transformMat2D(
          Vec2D(), vertex.translation, vertex.path.worldTransform);

      // Transform...
      Vec2D.add(worldTranslation, worldTranslation, delta);

      // Back to local
      vertex.translation = Vec2D.transformMat2D(
          Vec2D(), worldTranslation, vertex.path.inverseWorldTransform);
    }
  }

  @override
  void complete() {}

  @override
  bool init(Set<StageItem> items, DragTransformDetails details) {
    _stageVertices = items.whereType<StageVertex>();
    return _stageVertices.isNotEmpty;
  }
}
