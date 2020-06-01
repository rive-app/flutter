import 'dart:ui';

import 'package:core/core.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/component_dirt.dart';
import 'package:rive_core/event.dart';
import 'package:rive_core/src/generated/backboard_base.dart';
export 'package:rive_core/src/generated/backboard_base.dart';

class Backboard extends BackboardBase {
  // -> editor-only
  /// An event fired when the active artboard changes, this should probably be
  /// removed from the runtimes.
  final Event activeArtboardChanged = Event();

  Artboard _activeArtboard;
  Artboard get activeArtboard => _activeArtboard;
  set activeArtboard(Artboard value) {
    if (_activeArtboard == value) {
      return;
    }
    _activeArtboard = value;
    activeArtboardId = value?.id;
    activeArtboardChanged.notify();
  }

  @override
  void activeArtboardIdChanged(Id from, Id to) {
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
    _mainArtboard = context?.resolve(to);
    _mainArtboard?.addDirt(ComponentDirt.paint);
  }

  Color get color => Color(colorValue);
  set color(Color c) {
    colorValue = c.value;
  }

  @override
  void colorValueChanged(int from, int to) {}

  // <- editor-only

  @override
  void onAdded() {}

  @override
  void onAddedDirty() {}

  @override
  void onRemoved() {}
}
