import 'package:rive_editor/widgets/inspector/backboard_inspector_builder.dart';
import 'package:rive_editor/widgets/inspector/fills_inspector_builder.dart';
// import 'package:rive_editor/widgets/inspector/alignment_inspector_builder.dart';
import 'package:rive_editor/widgets/inspector/artboard_inspector_builder.dart';
import 'package:rive_editor/widgets/inspector/inspect_blend.dart';
import 'package:rive_editor/widgets/inspector/inspect_clipping.dart';
import 'package:rive_editor/widgets/inspector/inspect_transform.dart';
// import 'package:rive_editor/widgets/inspector/inspect_comboboxes_example.dart';
import 'package:rive_editor/widgets/inspector/inspector_builder.dart';
import 'package:rive_editor/widgets/inspector/strokes_inspector_builder.dart';

/// The list of possible inspector builders, these are iterated, validated, and
/// expanded when the inspector is built from the selection set.
final List<InspectorBuilder> defaultInspectorBuilders = [
  // AlignmentInspectorBuilder(),
  BackboardInspectorBuilder(),
  ArtboardInspectorBuilder(),
  TransformInspectorBuilder(),
  BlendInspectorBuilder(),
  FillsInspectorBuilder(),
  StrokesInspectorBuilder(),
  InspectClipping(),
  // InspectComboBoxExample(),
];
