import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/shapes/path_vertex.dart';
import 'package:rive_editor/rive/stage/items/stage_control_vertex.dart';
import 'package:rive_editor/rive/stage/items/stage_path_vertex.dart';
import 'package:rive_editor/rive/stage/items/stage_vertex.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/transformers/stage_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transforming_tool.dart';

/// Transformer that translates [StageItem]'s with underlying [Node] components.
class PathVertexTranslateTransformer extends StageTransformer {
  Iterable<StageVertex<PathVertex>> _stageVertices;

  @override
  void advance(DragTransformDetails details) {
    for (final stageVertex in _stageVertices) {
      var delta = details.world.delta;

      stageVertex.worldTranslation =
          Vec2D.add(Vec2D(), stageVertex.worldTranslation, delta);

      if (stageVertex is StageControlVertex) {
        switch (stageVertex.component.controlType) {
          case VertexControlType.mirrored:
            var diff = Vec2D.subtract(Vec2D(),
                stageVertex.component.translation, stageVertex.translation);
            stageVertex.sibling.translation =
                Vec2D.add(Vec2D(), diff, stageVertex.component.translation);
            break;
          case VertexControlType.asymmetric:
            var diff = Vec2D.subtract(Vec2D(),
                stageVertex.component.translation, stageVertex.translation);
            var siblingDiff = Vec2D.subtract(
                Vec2D(),
                stageVertex.component.translation,
                stageVertex.sibling.translation);

            var length = Vec2D.length(siblingDiff);
            Vec2D.normalize(diff, diff);

            stageVertex.sibling.translation = Vec2D.add(
                Vec2D(),
                Vec2D.scale(diff, diff, length),
                stageVertex.component.translation);
            break;
          default:
            break;
        }
      } else {
        var stagePathVertex = stageVertex as StagePathVertex;
        if (stagePathVertex.hasControlPoints) {
          stagePathVertex.controlIn.worldTranslation = Vec2D.add(
              Vec2D(), stagePathVertex.controlIn.worldTranslation, delta);
          stagePathVertex.controlOut.worldTranslation = Vec2D.add(
              Vec2D(), stagePathVertex.controlOut.worldTranslation, delta);
        }
      }
    }
  }

  @override
  void complete() {}

  @override
  bool init(Set<StageItem> items, DragTransformDetails details) {
    var valid = _stageVertices = <StageVertex<PathVertex>>[];
    var vertices = items.whereType<StageVertex<PathVertex>>().toSet();
    for (final stageVertex in vertices) {
      if (stageVertex is StageControlVertex) {
        var vertex = stageVertex.component;
        if (
            // Does the operation contain the vertex this control point belongs
            // to? If so, exclude it as translating the vertex moves the control
            // points.
            vertices.contains(vertex.stageItem) ||
                // If the sibling is in the selection set, neither of them move.
                ((vertex.controlType == VertexControlType.mirrored ||
                        vertex.controlType == VertexControlType.asymmetric) &&
                    vertices.contains(stageVertex.sibling))) {
          continue;
        }
      }
      valid.add(stageVertex);
    }
    return valid.isNotEmpty;
  }
}
