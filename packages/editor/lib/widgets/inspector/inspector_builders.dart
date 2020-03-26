import 'package:rive_editor/widgets/inspector/backboard_inspector_builder.dart';
import 'package:rive_editor/widgets/inspector/fills_inspector_builder.dart';
import 'package:rive_editor/widgets/inspector/alignment_inspector_builder.dart';
import 'package:rive_editor/widgets/inspector/artboard_inspector_builder.dart';
import 'package:rive_editor/widgets/inspector/inspect_comboboxes_example.dart';
import 'package:rive_editor/widgets/inspector/inspector_builder.dart';
import 'package:rive_editor/widgets/inspector/strokes_inspector_builder.dart';

import 'inspect_transform.dart';

/// The list of possible inspector builders, these are iterated, validated, and
/// expanded when the inspector is built from the selection set.
final List<InspectorBuilder> inspectorBuilders = [
  AlignmentInspectorBuilder(),
  BackboardInspectorBuilder(),
  ArtboardInspectorBuilder(),
  TransformInspectorBuilder(),
  FillsInspectorBuilder(),
  StrokesInspectorBuilder(),
  InspectComboBoxExample(),
];
