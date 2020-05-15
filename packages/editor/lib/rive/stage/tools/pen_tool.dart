import 'dart:ui';

import 'package:rive_core/artboard.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/stage_tool.dart';
import 'package:utilities/list_equality.dart';
import 'package:meta/meta.dart';

abstract class PenTool<T extends Component> extends StageTool {
  Iterable<T> _editing;
  Iterable<T> get editing => _editing;

  @override
  bool get activateSendsMouseMove => true;
  
  @override
  void draw(Canvas canvas) {
    if (_ghostPointScreen == null) {
      return;
    }
    _paintVertex(canvas, Offset(_ghostPointScreen[0], _ghostPointScreen[1]));
  }

  void _paintVertex(Canvas canvas, Offset offset) {
    // Draw twice: once for the background stroke, and a second time for
    // the foreground
    canvas.drawCircle(offset, 4.5, Paint()..color = const Color(0x19000000));
    canvas.drawCircle(offset, 3.5, Paint()..color = const Color(0xFFFFFFFF));
  }

  Vec2D _ghostPointWorld;
  Vec2D _ghostPointScreen;

  Vec2D get ghostPointWorld => _ghostPointWorld;

  void _showGhostPoint(Vec2D world) {
    _ghostPointWorld = Vec2D.clone(world);
    _ghostPointScreen = Vec2D.transformMat2D(Vec2D(),
        stageWorldSpace(stage.activeArtboard, world), stage.viewTransform);
    stage.markNeedsRedraw();
  }

  bool get isShowingGhostPoint => _ghostPointScreen != null;

  void _hideGhostPoint() {
    if (_ghostPointWorld != null) {
      _ghostPointWorld = null;
      _ghostPointScreen = null;
      stage.markNeedsRedraw();
    }
  }

  @override
  void mouseExit(Artboard activeArtboard, Vec2D worldMouse) {
    _hideGhostPoint();
  }

  @override
  bool mouseMove(Artboard activeArtboard, Vec2D worldMouse) {
    if (stage.hoverItem != null || stage.isPanning) {
      _hideGhostPoint();
      // TODO: mark insert target null
      return false;
    } else if (_editing == null) {
      // If we're not editing anything yet, show the ghost point as it'll
      // signify 'create a new whatever we're creating' (PenTool is implemented
      // by both Vector and Mesh pen tools).
      _showGhostPoint(worldMouse);
      // TODO: mark insert target null
      return true;
    }

    // TODO: find an insert target.
    _showGhostPoint(worldMouse);
    return false;
  }

  @override
  bool activate(Stage stage) {
    if (super.activate(stage)) {
      // Immediately draw our vertex.
      stage.markNeedsRedraw();

      stage.soloListenable.addListener(_stageSoloChanged);
      _updateEditing();
      return true;
    }
    return false;
  }

  void _stageSoloChanged() {
    // When the solo changes, we want to see if it affects what we are currently
    // editing.
    _updateEditing();
  }

  /// Compute the editing components from the set of solo stage items.
  Iterable<T> getEditingComponents(Iterable<StageItem> solo);

  void _updateEditing() {
    _setEditing(getEditingComponents(stage.soloItems));
  }

  @protected
  void onEditingChanged(Iterable<T> items);

  void _setEditing(Iterable<T> items) {
    if (iterableEquals(_editing, items)) {
      return;
    }

    // Remove previously set listeners.
    if (_editing != null) {
      for (final editing in _editing) {
        editing.stageItem.onRemoved.removeListener(_updateEditing);
      }
    }

    _editing = items;
    onEditingChanged(items);

    // Register listeners for when one of our editing items is removed from the
    // stage.
    if (_editing != null) {
      for (final editing in _editing) {
        editing.stageItem.onRemoved.addListener(_updateEditing);
      }
    }
  }

  @override
  void deactivate() {
    stage.soloListenable.removeListener(_stageSoloChanged);
    // Redraw without our vertex.
    stage?.markNeedsRedraw();
    _setEditing(null);
    super.deactivate();
  }

  @override
  String get icon => 'tool-pen';
}
