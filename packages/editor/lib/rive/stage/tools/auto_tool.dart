import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:rive_core/artboard.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/rive/stage/stage_drawable.dart';
import 'package:rive_editor/rive/stage/tools/transformers/stage_transformer.dart';
import 'package:rive_editor/rive/stage/tools/translate_tool.dart';
import 'package:rive_editor/selectable_item.dart';
import 'package:rive_editor/widgets/theme.dart';
import 'package:utilities/restorer.dart';
import 'package:rive_editor/rive/stage/tools/transform_handle_tool.dart';

class AutoTool extends TransformHandleTool {
  final Paint _stroke = Paint()
    ..strokeWidth = 1
    ..color = RiveColors().keyMarqueeStroke
    ..style = PaintingStyle.stroke;
  final Paint _fill = Paint()..color = RiveColors().keyMarqueeFill;

  Vec2D _marqueeStart;
  Vec2D _marqueeEnd;

  bool get isMarqueeing => _marqueeStart != null;

  @override
  Iterable<StageDrawPass> get drawPasses =>
      [StageDrawPass(draw, order: 1000, inWorldSpace: false)];

  // We operate in stage space
  @override
  bool get inArtboardSpace => false;

  AABB get marqueeBounds {
    if (_marqueeStart == null || _marqueeEnd == null) {
      return null;
    }

    return AABB.fromValues(
      min(_marqueeEnd[0], _marqueeStart[0]),
      min(_marqueeEnd[1], _marqueeStart[1]),
      max(_marqueeEnd[0], _marqueeStart[0]),
      max(_marqueeEnd[1], _marqueeStart[1]),
    );
  }

  AABB get viewMarqueeBounds => marqueeBounds?.transform(stage.viewTransform);

  @override
  void draw(Canvas canvas, StageDrawPass drawPass) {
    drawTransformers(canvas);
    var marquee = viewMarqueeBounds;
    if (marquee == null) {
      return;
    }

    var rect = Rect.fromLTRB(
      marquee[0] - 0.5,
      marquee[1] - 0.5,
      marquee[2] + 0.5,
      marquee[3] + 0.5,
    );

    canvas.drawRect(rect, _fill);
    canvas.drawRect(rect, _stroke);
  }

  @override
  Iterable<PackedIcon> get icon => PackedIcon.toolAuto;

  static final AutoTool instance = AutoTool();

  HashSet<SelectableItem> _preSelected;
  Restorer _restoreSelect;

  @override
  bool activate(Stage stage) {
    ShortcutAction.multiSelect.addListener(_toggleMultiSelect);
    stage.file.addActionHandler(_handleAction);
    return super.activate(stage);
  }

  @override
  void deactivate() {
    ShortcutAction.multiSelect.removeListener(_toggleMultiSelect);
    stage.file.removeActionHandler(_handleAction);
    super.deactivate();
  }

  void _toggleMultiSelect() {
    if (isMarqueeing) {
      _updateMarquee();
    }
  }

  @override
  void click(Artboard activeArtboard, Vec2D worldMouse) {
    super.click(activeArtboard, worldMouse);

    if (!isTransforming && stage.mouseDownHit == null) {
      _restoreSelect = stage.suppressSelection();
      _marqueeStart = Vec2D.clone(worldMouse);
      _preSelected = ShortcutAction.multiSelect.value
          ? HashSet<SelectableItem>.of(stage.file.selection.items)
          : HashSet<SelectableItem>();

      // Immediately clear the selection so we can see an empty selected set in
      // the hierarchy (which doesn't update while marqueeing, so an empty
      // selection state is at least less confusing).
      if (_preSelected.isEmpty) {
        stage.file.selection.clear();
      }
    }
  }

  @override
  bool endClick() {
    _restoreSelect?.restore();
    if (isMarqueeing) {
      // Notify any stage items and listeners of their selection change. We
      // suppress this during marqueeing to keep it snappy and rebuild UI
      // minimally.
      stage.file.selection.notifySelection();
    }

    _marqueeStart = _marqueeEnd = null;
    return false;
  }

  void _updateMarquee() {
    var inMarquee = HashSet<SelectableItem>();

    var bounds = marqueeBounds;
    var marqueeMinX = bounds[0];
    var marqueeMinY = bounds[1];
    var marqueeMaxX = bounds[2];
    var marqueeMaxY = bounds[3];

    Float32List marqueePoly = Float32List.fromList([
      marqueeMinX,
      marqueeMinY,
      marqueeMaxX,
      marqueeMinY,
      marqueeMaxX,
      marqueeMaxY,
      marqueeMinX,
      marqueeMaxY,
    ]);

    stage.visTree.query(marqueeBounds, (proxyId, hitItem) {
      var item = hitItem.selectionTarget;
      if (item.isVisible &&
          item.isSelectable &&
          !_preSelected.contains(item) &&
          (stage.soloItems == null || stage.isValidSoloSelection(item)) &&
          item.intersectsRect(marqueePoly)) {
        inMarquee.add(item);
      }

      return true;
    });

    var fullSelection = HashSet<SelectableItem>.of(_preSelected);
    fullSelection.addAll(inMarquee);

    if (ShortcutAction.multiSelect.value) {
      // When multi-selecting, remove intersection from the set.
      fullSelection.removeAll(_preSelected.intersection(inMarquee));
    }

    stage.file.selection.selectMultiple(
      fullSelection,
      notify: false,
    );

    stage.markNeedsRedraw();
  }

  @override
  void updateDrag(Vec2D worldMouse) {
    if (!isMarqueeing) {
      return;
    }
    _marqueeEnd = Vec2D.clone(worldMouse);

    _updateMarquee();
  }

  // We grab the transformers from the translate tool if we're dragging an item.
  @override
  List<StageTransformer> get transformers => isTransforming
      ? super.transformers
      : isMarqueeing
          ? []
          : TranslateTool.instance.transformers;

  /// Handle any shortcuts that affect the auto tool.
  /// In this case, if escape is pressed, deselect all
  /// selected items.
  bool _handleAction(ShortcutAction action) {
    switch (action) {
      case ShortcutAction.cancel:
        if (isMarqueeing) {
          // Clear the selection
          stage.file.selection.clear();
          // Cancel the marqueeing
          _marqueeStart = _marqueeEnd = null;
          return true;
        }
        return false;
      default:
        return false;
    }
  }

  @override
  bool validateDrag() => validateClick();
}
