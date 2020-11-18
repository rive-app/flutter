import 'dart:math';
import 'dart:ui';

import 'package:rive_core/artboard.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/shapes/paint/fill.dart';
import 'package:rive_core/shapes/paint/solid_color.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/rive/stage/stage_drawable.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/create_tool.dart';
import 'package:rive_editor/rive/stage/tools/stage_tool_tip.dart';

class ArtboardTool extends CreateTool {
  @override
  Iterable<PackedIcon> get cursorName => PackedIcon.cursorAdd;

  Vec2D _startWorldMouse;
  Artboard _artboard;

  // Required to track cursor position and disaply tool tip when dragging
  final _tip = StageToolTip();
  Vec2D _cursor;

  /// The artboard tool operates in stage world space.
  @override
  bool get inArtboardSpace => false;

  @override
  bool validateClick() {
    // Artboard tool can always be clicked, regardless of whether or not there's
    // an artboard (see super.validateClick).
    return true;
  }

  @override
  bool activate(Stage stage) {
    if (!super.activate(stage)) {
      return false;
    }
    // Start listening for edit mode changes
    _symmetricDrawChanged();
    ShortcutAction.symmetricDraw.addListener(_symmetricDrawChanged);
    _artboard = null;
    return true;
  }

  @override
  void deactivate() {
    super.deactivate();
    ShortcutAction.symmetricDraw.removeListener(_symmetricDrawChanged);
  }

  @override
  void startDrag(Iterable<StageItem> selection, Artboard activeArtboard,
      Vec2D worldMouse) {
    super.startDrag(selection, activeArtboard, worldMouse);
    // Create an artboard and place it at the world location.
    _startWorldMouse = Vec2D.clone(worldMouse);
    _startWorldMouse[0] = _startWorldMouse[0].roundToDouble();
    _startWorldMouse[1] = _startWorldMouse[1].roundToDouble();
    var file = stage.file;
    var core = file.core;
    core.batchAdd(() {
      var solidColor = SolidColor()..colorValue = 0xFF313131;
      var fill = Fill();
      _artboard = Artboard()
        ..x = worldMouse[0].roundToDouble()
        ..y = worldMouse[1].roundToDouble()
        ..originX = 0
        ..originY = 0
        ..width = 1
        ..height = 1;
      core.addObject(_artboard);
      core.addObject(fill);
      core.addObject(solidColor);
      _artboard.appendChild(fill);
      fill.appendChild(solidColor);
    });
  }

  @override
  void updateDrag(Vec2D worldMouse) {
    if (ShortcutAction.symmetricDraw.value) {
      final maxChange = max(
        (_startWorldMouse[0] - worldMouse[0]).abs(),
        (_startWorldMouse[1] - worldMouse[1]).abs(),
      );
      var x1 = (_startWorldMouse[0] < worldMouse[0])
          ? _startWorldMouse[0]
          : _startWorldMouse[0] - maxChange;
      var y1 = (_startWorldMouse[1] < worldMouse[1])
          ? _startWorldMouse[1]
          : _startWorldMouse[1] - maxChange;
      _artboard.x = x1.roundToDouble();
      _artboard.y = y1.roundToDouble();
      _artboard.width = maxChange.roundToDouble();
      _artboard.height = maxChange.roundToDouble();
    } else {
      _artboard.x = min(_startWorldMouse[0], worldMouse[0]).roundToDouble();
      _artboard.y = min(_startWorldMouse[1], worldMouse[1]).roundToDouble();
      _artboard.width =
          (_startWorldMouse[0] - worldMouse[0]).abs().roundToDouble();
      _artboard.height =
          (_startWorldMouse[1] - worldMouse[1]).abs().roundToDouble();
    }

    _cursor = Vec2D.clone(worldMouse);
    _tip.text = '${_artboard.width.round()}x${_artboard.height.round()}';
  }

  @override
  void endDrag() {
    if (_artboard != null) {
      stage.file.select(_artboard.stageItem);
    }
    _artboard = null;
    _cursor = null;
  }

  @override
  void draw(Canvas canvas, StageDrawPass drawPass) {
    if (_cursor == null) {
      return;
    }
    var cursorScreen =
        Vec2D.transformMat2D(Vec2D(), _cursor, stage.viewTransform);
    _tip.paint(canvas, Offset(cursorScreen[0] + 10, cursorScreen[1] + 10));
  }

  @override
  Iterable<PackedIcon> get icon => PackedIcon.toolArtboard;

  static final ArtboardTool instance = ArtboardTool();

  void _symmetricDrawChanged() {
    if (lastWorldMouse != null && _artboard != null) {
      updateDrag(lastWorldMouse);
    }
  }
}
