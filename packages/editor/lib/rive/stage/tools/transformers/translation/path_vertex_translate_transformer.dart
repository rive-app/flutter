import 'dart:collection';
import 'dart:math';
import 'dart:ui';

import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/shapes/path_vertex.dart';
import 'package:rive_core/shapes/cubic_mirrored_vertex.dart';
import 'package:rive_core/shapes/cubic_asymmetric_vertex.dart';
import 'package:rive_editor/rive/stage/items/stage_control_vertex.dart';
import 'package:rive_editor/rive/stage/items/stage_vertex.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/stage_tool_tip.dart';
import 'package:rive_editor/rive/stage/tools/transformers/stage_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transforming_tool.dart';

/// Transformer that translates [StageItem]'s with underlying [Node] components.
class PathVertexTranslateTransformer extends StageTransformer {
  Iterable<StageVertex<PathVertex>> _stageVertices;
  final HashMap<StageControlVertex, double> _startingAngles =
      HashMap<StageControlVertex, double>();

  @override
  void advance(DragTransformDetails details) {
    for (final stageVertex in _stageVertices) {
      var delta = details.world.delta;

      stageVertex.worldTranslation =
          Vec2D.add(Vec2D(), stageVertex.worldTranslation, delta);
    }
  }

  @override
  void complete() {
    for (final stageVertex in _stageVertices) {
      if (stageVertex is StageControlVertex) {
        stageVertex.component.accumulateAngle = false;
      }
    }
    _stageVertices = [];
  }

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
                ((vertex.coreType == CubicMirroredVertexBase.typeKey ||
                        vertex.coreType == CubicAsymmetricVertexBase.typeKey) &&
                    vertices.contains(stageVertex.sibling))) {
          continue;
        }
      }

      if (stageVertex is StageControlVertex) {
        stageVertex.component.accumulateAngle = true;
        _startingAngles[stageVertex] = stageVertex.angle;
      }
      valid.add(stageVertex);
    }
    return valid.isNotEmpty;
  }

  static final Paint strokeOuter = Paint()
    ..style = PaintingStyle.stroke
    // Stroke is 3 so 1.5 sticks out when we draw fill over it.
    ..strokeWidth = 3
    ..color = const Color(0x26000000);
  static final Paint strokeInner = Paint()
    ..style = PaintingStyle.stroke
    // Stroke is 3 so 1.5 sticks out when we draw fill over it.
    ..strokeWidth = 1
    ..color = const Color(0xFFFFF1BE);
  static final Paint fill = Paint()..color = const Color(0x80FFF1BE);

  final _tip = StageToolTip();

  @override
  void draw(Canvas canvas) {
    for (final stageVertex in _stageVertices) {
      if (stageVertex is StageControlVertex) {
        var stage = stageVertex.stage;
        var vertexStageItem = stageVertex.component.stageItem as StageVertex;
        canvas.save();

        // canvas.transform(stage.inverseViewTransform.mat4);
        var screenTranslation = Vec2D.transformMat2D(
            Vec2D(), vertexStageItem.worldTranslation, stage.viewTransform);
        canvas.translate(screenTranslation[0].roundToDouble() + 0.5,
            screenTranslation[1].roundToDouble() + 0.5);
        double radius = 20;
        var rect = Rect.fromLTRB(-radius, -radius, radius, radius);

        var startingAngle = _startingAngles[stageVertex];
        var endingAngle = stageVertex.angle;

        var sweep = endingAngle - startingAngle;

        if (sweep < 0) {
          var s = startingAngle;
          startingAngle = endingAngle;
          endingAngle = s;
          sweep = endingAngle - startingAngle;
        }

        var loops = (sweep / (pi * 2)).abs().floor();
        for (var i = 0; i < loops; i++) {
          canvas.drawOval(rect, fill);
        }

        _tip.text =
            'Length ${stageVertex.length.round()}\n'
            'Angle ${(stageVertex.angle / pi * 180).round()}°';

        canvas.drawArc(rect, startingAngle,
            (endingAngle - startingAngle) % (pi * 2), true, fill);
        canvas.drawOval(rect, strokeOuter);
        canvas.drawOval(rect, strokeInner);
        canvas.restore();

        _tip.paint(
            canvas, Offset(stage.localMouse.dx + 10, stage.localMouse.dy + 10));
      }
    }
  }
}
