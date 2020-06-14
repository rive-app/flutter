import 'dart:collection';
import 'dart:math';
import 'dart:ui';

import 'package:rive_core/artboard.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/draggable_tool.dart';
import 'package:rive_editor/rive/stage/tools/stage_tool.dart';
import 'package:rive_editor/selectable_item.dart';
import 'package:rive_editor/widgets/theme.dart';

class AutoTool extends StageTool with DraggableTool {
  final Paint _stroke = Paint()
    ..strokeWidth = 1
    ..color = RiveColors().keyMarqueeStroke
    ..style = PaintingStyle.stroke;
  final Paint _fill = Paint()..color = RiveColors().keyMarqueeFill;

  Vec2D _marqueeStart;
  Vec2D _marqueeEnd;

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
  void draw(Canvas canvas) {
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
  @override
  void startDrag(
    Iterable<StageItem> selection,
    Artboard activeArtboard,
    Vec2D worldMouse,
  ) {
    super.startDrag(selection, activeArtboard, worldMouse);
    _marqueeStart = Vec2D.clone(worldMouse);
    _preSelected = HashSet<SelectableItem>.of(stage.file.selection.items);
  }

  @override
  void endDrag() {
    _marqueeStart = _marqueeEnd = null;
  }

  @override
  void updateDrag(Vec2D worldMouse) {
    _marqueeEnd = Vec2D.clone(worldMouse);

    var inMarquee = HashSet<SelectableItem>();
    stage.visTree.query(marqueeBounds, (proxyId, hitItem) {
      var item = hitItem.selectionTarget;
      if (item.isVisible && item.isSelectable) {
        // TODO: need to implement a hitRect.
        inMarquee.add(item);
      }
      return true;
    });

    stage.file.selection.selectMultiple(
      HashSet<SelectableItem>.of(_preSelected)..addAll(inMarquee),
    );

    stage.markNeedsRedraw();
  }
}
