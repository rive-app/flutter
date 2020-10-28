import 'dart:ui';

import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/rive/stage/stage_drawable.dart';
import 'package:rive_editor/rive/stage/tools/transformers/stage_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transformers/translation/artboard_translate_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transformers/translation/node_translate_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transformers/translation/joint_translate_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transformers/translation/gradient_stop_translate_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transformers/translation/path_vertex_translate_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transform_handle_tool.dart';

class TranslateTool extends TransformHandleTool {
  TranslateTool()
      : super(
          hasRotationHandle: false,
          hasScaleHandles: false,
        );

  @override
  Iterable<PackedIcon> get icon => PackedIcon.toolTranslate;

  // Draw before the vertex handles but after artboard drawables.
  @override
  Iterable<StageDrawPass> get drawPasses => [
        StageDrawPass(draw, order: 1000, inWorldSpace: false),
      ];

  @override
  bool get showRotationHandle => false;

  @override
  bool get showScaleHandle => false;

  @override
  List<StageTransformer> get transformers => isTransforming
      ? super.transformers
      : [
          // gradient stop transformers must come before other transformers in
          // order to allow them to cull nodes from the transformation set
          GradientStopTranslateTransformer(),

          ArtboardTranslateTransformer(),

          NodeTranslateTransformer(),

          JointTranslateTransformer(),

          PathVertexTranslateTransformer(
            lockRotationShortcut: ShortcutAction.symmetricDraw,
          ),
        ];

  static final TranslateTool instance = TranslateTool();

  @override
  void draw(Canvas canvas, StageDrawPass drawPass) {
    drawTransformers(canvas);
  }

  @override
  bool validateDrag() => validateClick();
}
