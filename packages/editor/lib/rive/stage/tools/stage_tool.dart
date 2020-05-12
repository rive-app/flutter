import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:rive_core/artboard.dart';
import 'package:rive_core/math/vec2d.dart';

import 'package:rive_editor/constants.dart';
import 'package:rive_editor/rive/stage/stage.dart';

abstract class StageTool {
  Stage _stage;
  Stage get stage => _stage;

  String get icon;

  EditMode _editMode;
  EditMode get editMode => _editMode;

  /// Most tools will want their transforms in artboard world space.
  bool get inArtboardSpace => true;

  /// Gets the correct mouse world space depending on whether this tool operates
  /// in stage world or artboard world. Because the artboards don't rotate or
  /// scale (at least not on the stage), this is just a simple translation
  /// operation.
  Vec2D mouseWorldSpace(Artboard activeArtboard, Vec2D worldMouse) =>
      inArtboardSpace
          ? Vec2D.subtract(Vec2D(), worldMouse, activeArtboard.originWorld)
          : worldMouse;

  Vec2D stageWorldSpace(Artboard activeArtboard, Vec2D worldMouse) =>
      inArtboardSpace
          ? Vec2D.add(Vec2D(), worldMouse, activeArtboard.originWorld)
          : worldMouse;

  /// Override this to check if this tool is valid.
  @mustCallSuper
  bool activate(Stage stage) {
    _stage = stage;
    return true;
  }

  /// Cleanup anything that was setup during activation.
  void deactivate() {}

  void setEditMode(EditMode editMode) {
    _editMode = editMode;
    onEditModeChange();
  }

  void onEditModeChange() {}
  void draw(Canvas canvas);

  /// Called when the tool focus is considered offscreen
  /// e.g. the mouse moves outside the stage boundaries
  void offScreen() {}

  /// Called when the tool focus is considered to have moved on screen
  /// e.g. the mouse moves to be inside the stage boundaries
  void onScreen() {}
}
