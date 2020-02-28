import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:rive_editor/rive/stage/stage.dart';

enum EditMode { normal, altMode1, altMode2 }

abstract class StageTool {
  Stage _stage;
  Stage get stage => _stage;

  String get icon;

  EditMode _editMode;
  EditMode get editMode => _editMode;

  /// Override this to check if this tool is valid.
  bool activate(Stage stage) {
    _stage = stage;
    return true;
  }

  void setEditMode(EditMode editMode) {
    _editMode = editMode;
    onEditModeChange();
  }

  void onEditModeChange() {}
  void paint(Canvas canvas);
}
