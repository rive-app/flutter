import 'dart:ui';

import 'package:rive_editor/rive/stage/tools/transformers/stage_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transformers/translation/artboard_translate_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transformers/translation/node_translate_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transformers/translation/gradient_stop_translate_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transforming_tool.dart';

import 'stage_tool.dart';

class TranslateTool extends StageTool with TransformingTool {
  @override
  void draw(Canvas canvas) {}

  @override
  String get icon => 'tool-translate';

  @override
  List<StageTransformer> get transformers => [
        ArtboardTranslateTransformer(),

        // gradient stop transformers must come before node transformers in
        // order to allow them to cull nodes from the transformation set
        GradientStopTranslateTransformer(),

        NodeTranslateTransformer(),
      ];

  static final TranslateTool instance = TranslateTool();
}
