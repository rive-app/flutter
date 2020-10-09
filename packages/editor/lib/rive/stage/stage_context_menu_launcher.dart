import 'dart:ui';

import 'package:rive_editor/widgets/popup/popup.dart';

/// Event details provided when the Stage wants to display a popup.
class StageContextMenuDetails {
  final List<PopupContextItem> items;
  final Offset position;

  StageContextMenuDetails(this.items, double x, double y)
      : position = Offset(x, y);
}

/// Abstraction for StageItems to implement to provide contextMenuItems when
/// they are right clicked on.
abstract class StageContextMenuLauncher {
  List<PopupContextItem> get contextMenuItems;
}
