import 'dart:ui';

import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/rive/stage/tools/transformers/stage_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transformers/translation/artboard_translate_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transformers/translation/node_translate_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transformers/translation/gradient_stop_translate_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transformers/translation/path_vertex_translate_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transforming_tool.dart';

import 'stage_tool.dart';

class TranslateTool extends StageTool with TransformingTool {
  @override
  Iterable<PackedIcon> get icon => PackedIcon.toolTranslate;

  // Draw before the vertex handles but after artboard drawables.
  @override
  int get drawOrder => 2;

  @override
  List<StageTransformer> get transformers => [
        // gradient stop transformers must come before other transformers in
        // order to allow them to cull nodes from the transformation set
        GradientStopTranslateTransformer(),

        ArtboardTranslateTransformer(),

        NodeTranslateTransformer(),

        PathVertexTranslateTransformer(),
      ];

  static final TranslateTool instance = TranslateTool();

  @override
  void draw(Canvas canvas) {
    drawTransformers(canvas);
  }
}
