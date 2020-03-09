import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/inspector/inspection_set.dart';

/// An editor building function which is expected to return a list of builders
/// based on the current inspecting set. Note that this returns a list of
/// [WidgetBuilder]s so that a virtualized ListView can be built, preventing
/// every widget in a potentially very large inspector panel from built at once.
typedef InspectorExpander = List<WidgetBuilder> Function(InspectionSet);

abstract class InspectorBuilder {
  /// Validate must ensure that the inspecting set has sensible data that the
  /// expander can work with.
  bool validate(InspectionSet inspecting);

  /// Gauranteed to be called only when sensible data is available.
  List<WidgetBuilder> expand(InspectionSet inspecting);
}
