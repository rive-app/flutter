import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:rive_core/artboard.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/rive/rive.dart';
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
  void click(Artboard activeArtboard, Vec2D worldMouse) {
    super.click(activeArtboard, worldMouse);

    if (!isTransforming && !stage.mouseDownSelected) {
      _restoreSelect = stage.suppressSelection();
      _marqueeStart = Vec2D.clone(worldMouse);
      _preSelected = stage.file.selectionMode == SelectionMode.range
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

  @override
  void updateDrag(Vec2D worldMouse) {
    if (!isMarqueeing) {
      return;
    }
    _marqueeEnd = Vec2D.clone(worldMouse);

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
      if (item.isVisible && item.isSelectable) {
        // Items are required to have an OBB to be selectable by the marquee. If
        // further refinement is necessary, consider adding an
        // isMarqueeSelectable getter to StageItem.
        if (item.obb != null) {
          if (_doRectsIntersect(marqueePoly, item.obb.poly)) {
            inMarquee.add(item);
          }
        }
      }
      return true;
    });

    stage.file.selection.selectMultiple(
      HashSet<SelectableItem>.of(_preSelected)..addAll(inMarquee),
      notify: false,
    );

    stage.markNeedsRedraw();
  }

  // We grab the transformers from the translate tool if we're dragging an item.
  @override
  List<StageTransformer> get transformers => isTransforming
      ? super.transformers
      : isMarqueeing ? [] : TranslateTool.instance.transformers;
}

/// Tests for rectangle intersection given the polygon contour of the rects.
/// This can be changed into a more general polygon intersector by removing
/// length/2 in each of the outer for loops. We can get away with projecting to
/// only two axes if we know we're dealing with rectangles.
bool _doRectsIntersect(Float32List a, Float32List b) {
  var al = a.length;
  var bl = b.length;
  for (int i = 0, l = a.length ~/ 2; i < l; i += 2) {
    // Finds a line perpendicular to the edge. normal = x: p2.y - p1.y, y: p1.x
    // - p2.x
    var x = a[(i + 3) % al] - a[i + 1];
    var y = a[i] - a[(i + 2) % al];

    // Project each point in a to the perpendicular edge.
    var projectA = _projectToEdge(a, x, y);
    var projectB = _projectToEdge(b, x, y);

    // if there is no overlap between the projects, the edge we are looking at
    // separates the two polygons, and we know there is no overlap
    if (projectA.max < projectB.min || projectB.max < projectA.min) {
      return false;
    }
  }
  for (int i = 0, l = b.length ~/ 2; i < l; i += 2) {
    // Finds a line perpendicular to the edge. normal = x: p2.y - p1.y, y: p1.x
    // - p2.x
    var x = b[(i + 3) % bl] - b[i + 1];
    var y = b[i] - b[(i + 2) % bl];

    // Project each point in a to the perpendicular edge.
    var projectA = _projectToEdge(a, x, y);
    var projectB = _projectToEdge(b, x, y);

    // if there is no overlap between the projects, the edge we are looking at
    // separates the two polygons, and we know there is no overlap
    if (projectA.max < projectB.min || projectB.max < projectA.min) {
      return false;
    }
  }
  return true;
}

class _Projection {
  final double min;
  final double max;

  _Projection(this.min, this.max);
}

/// Return results contains min/max.
_Projection _projectToEdge(Float32List points, double edgeX, double edgeY) {
// Project each point in a to the perpendicular edge.
  double min = double.maxFinite, max = -double.maxFinite;
  var pl = points.length;
  for (int j = 0; j < pl; j += 2) {
    var projection = edgeX * points[j] + edgeY * points[j + 1];
    if (projection < min) {
      min = projection;
    }
    if (projection > max) {
      max = projection;
    }
  }

  return _Projection(min, max);
}
