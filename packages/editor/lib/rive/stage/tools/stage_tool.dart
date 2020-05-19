import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:rive_core/artboard.dart';
import 'package:rive_core/math/vec2d.dart';

import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/rive/stage/stage_drawable.dart';

abstract class StageTool implements StageDrawable {
  Stage _stage;
  Stage get stage => _stage;

  String get icon;

  /// Most tools will want their transforms in artboard world space.
  bool get inArtboardSpace => true;

  // Whether this tool wants a mouseMove event triggered immediately when it is
  // activated, some tools will want this to sync up any internal data that is
  // dependent on mouse coordinates.
  bool get activateSendsMouseMove => false;

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
    return validate(stage);
  }

  /// Override this to validate if the tool is valid for the stage.
  bool validate(Stage stage) => true;

  /// Cleanup anything that was setup during activation.
  void deactivate() {}

  /// Set the draw order to something large as stage tools almost always draw
  /// last. TODO: dart doesn't provide a constant for integers, find out if max
  /// 64 bit int (9223372036854775807) transpiles nicely to js
  @override
  int get drawOrder => 1000;

  @override
  void draw(Canvas canvas);

  @override
  bool get drawsInWorldSpace => false;

  /// Returns true if the stage should advance after movement.
  bool mouseMove(Artboard activeArtboard, Vec2D worldMouse) {
    return false;
  }

  void mouseExit(Artboard activeArtboard, Vec2D worldMouse) {}
  void mouseEnter(Artboard activeArtboard, Vec2D worldMouse) {}
  void click(Artboard activeArtboard, Vec2D worldMouse) {}
  bool endClick() => false;
}
