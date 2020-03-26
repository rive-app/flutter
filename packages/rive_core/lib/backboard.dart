import 'dart:ui';

import 'package:core/core.dart';
import 'package:flutter/scheduler.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/component_dirt.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/src/generated/backboard_base.dart';
export 'package:rive_core/src/generated/backboard_base.dart';

class Backboard extends BackboardBase {
  Artboard _activeArtboard;
  Artboard get activeArtboard => _activeArtboard;
  set activeArtboard(Artboard value) {
    activeArtboardId = value.id;
  }

  @override
  void activeArtboardIdChanged(Id from, Id to) {
    super.activeArtboardIdChanged(from, to);
    _activeArtboard = context?.resolve(to);
    _activeArtboard?.addDirt(ComponentDirt.paint);
  }

  Artboard _mainArtboard;
  Artboard get mainArtboard => _mainArtboard;
  set mainArtboard(Artboard value) {
    mainArtboardId = value.id;
  }

  @override
  void mainArtboardIdChanged(Id from, Id to) {
    super.mainArtboardIdChanged(from, to);
    _mainArtboard = context?.resolve(to);
    _mainArtboard?.addDirt(ComponentDirt.paint);
  }

  Color get color => Color(colorValue);
  set color(Color c) {
    colorValue = c.value;
  }

  @override
  void colorValueChanged(int from, int to) {
    super.colorValueChanged(from, to);
  }

  @override
  void onAdded() {}

  @override
  void onAddedDirty() {}

  @override
  void onRemoved() {}
}
