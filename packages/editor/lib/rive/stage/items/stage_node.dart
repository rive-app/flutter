import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:rive_core/bounds_delegate.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/node.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/rive/stage/items/stage_expandable.dart';
import 'package:rive_editor/rive/stage/items/stage_transformable_component.dart';
import 'package:rive_editor/rive/stage/snapper.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/rive/stage/stage_drawable.dart';
import 'package:rive_editor/rive/stage/stage_hideable.dart';
import 'package:rive_editor/selectable_item.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';

enum StageNodeDisplay { node, group }

/// A Node component as it's drawn on the stage.
class StageNode extends HideableStageItem<Node>
    with
        BoundsDelegate,
        StageTransformableComponent<Node>,
        StageExpandable<Node> {
  @override
  ValueNotifier<bool> get isShownNotifier => stage.showNodesNotifier;

  @override
  StageItem get selectionTarget => ShortcutAction.deepClick.value
      ? this
      : StageExpandable.findNonExpanded(this);

  /// Can't check if we should draw if it's a group here, as this will also
  /// cause the bounds not to be drawn. Should we have two checks, isVisible and
  /// isBoundsVisible and then let the stage manage what's being hidden?
  @override
  bool get isVisible => super.isVisible; // !isGroup && super.isVisible;

  /// Returns true of this node is a group (i.e. it has children)
  bool get isGroup => component.children.isNotEmpty;

  @override
  Iterable<StageDrawPass> get drawPasses => [
        if (obb == null && !isGroup)
          StageDrawPass(
            draw,
            inWorldSpace: true,
            order: 11,
          ),
        if (shouldDrawBounds)
          StageDrawPass(
            drawBounds,
            inWorldSpace: false,
            order: 10,
          ),
      ];

  StageNodeDisplay get display =>
      obb == null ? StageNodeDisplay.node : StageNodeDisplay.group;

  @override
  bool computeBounds() {
    if (!super.computeBounds()) {
      // Failed to compute accumulated expandable bounds, we need to compute our
      // own.
      obb = null;
      aabb = AABB
          .fromValues(
              component.worldTransform[4] - _halfNodeSize,
              component.worldTransform[5] - _halfNodeSize,
              component.worldTransform[4] + _halfNodeSize,
              component.worldTransform[5] + _halfNodeSize)
          .translate(component.artboard.originWorld);
    }
    return true;
  }

  @override
  bool intersectsRect(Float32List rectPoly) => true;

  @override
  bool get isHoverSelectable => display == StageNodeDisplay.node;

  @override
  bool hitHiFi(Vec2D worldMouse) {
    if (obb == null) {
      return super.hitHiFi(worldMouse);
    }

    // Get world mouse in local component coordinate (use the inverse of the OBB
    // so we can use the OBB itself for overlap testing).
    var localMouse =
        Vec2D.transformMat2D(Vec2D(), worldMouse, obb.inverseTransform);
    return AABB.testOverlapPoint(obb.bounds, localMouse);
  }

  @override
  void draw(Canvas canvas, StageDrawPass pass) {
    // TODO: make this efficient
    final state = selectionState.value;
    if (state == SelectionState.hovered || state == SelectionState.selected) {
      _nodeStroke.color = _nodeFill.color = StageItem.selectedPaint.color;
    } else {
      _nodeStroke.color = _nodeFill.color = _pathColor;
    }
    canvas.save();
    final origin = component.artboard.originWorld;
    canvas.translate(origin[0], origin[1]);
    canvas.transform(component.worldTransform.mat4);
    canvas.drawPath(_nodeEdgePath, _nodeStroke);
    canvas.drawPath(_insidePath, _nodeFill);
    canvas.restore();
  }

  static const _nodeSize = 18;
  static const _halfNodeSize = _nodeSize / 2;
  static const _edgeSize = 6;
  static const _edgeThickness = 1.5;
  static const _halfEdgeThickness = _edgeThickness / 2;
  static const _pathColor = Color.fromRGBO(255, 255, 255, 0.5);
  static final Paint _nodeStroke = Paint()
    ..isAntiAlias = false
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..blendMode = BlendMode.srcOver
    ..color = _pathColor;

  static final Paint _nodeFill = Paint()
    ..isAntiAlias = false
    ..style = PaintingStyle.fill
    ..blendMode = BlendMode.srcOver
    ..color = _pathColor;

  // Lazily build the Canvas paths by using a closure that is evaulauted
  // in-place.
  // The following static fields are for when the node needs to be drawn
  // 'empty' (as opposed to 'target').
  static final Path _nodeEdgePath = () {
    final path = Path();
    path.moveTo(-_halfNodeSize + _halfEdgeThickness,
        -_halfNodeSize + _edgeSize - _halfEdgeThickness);
    path.lineTo(-_halfNodeSize + _halfEdgeThickness,
        -_halfNodeSize + _halfEdgeThickness);
    path.lineTo(-_halfNodeSize + _edgeSize - _halfEdgeThickness,
        -_halfNodeSize + _halfEdgeThickness);

    path.moveTo(_halfNodeSize - _edgeSize + _halfEdgeThickness,
        -_halfNodeSize + _halfEdgeThickness);
    path.lineTo(_halfNodeSize - _halfEdgeThickness,
        -_halfNodeSize + _halfEdgeThickness);
    path.lineTo(_halfNodeSize - _halfEdgeThickness,
        -_halfNodeSize + _edgeSize - _halfEdgeThickness);

    path.moveTo(_halfNodeSize - _halfEdgeThickness,
        _halfNodeSize - _edgeSize + _halfEdgeThickness);
    path.lineTo(
        _halfNodeSize - _halfEdgeThickness, _halfNodeSize - _halfEdgeThickness);
    path.lineTo(_halfNodeSize - _edgeSize + _halfEdgeThickness,
        _halfNodeSize - _halfEdgeThickness);

    path.moveTo(-_halfNodeSize + _edgeSize - _halfEdgeThickness,
        _halfNodeSize - _halfEdgeThickness);
    path.lineTo(-_halfNodeSize + _halfEdgeThickness,
        _halfNodeSize - _halfEdgeThickness);
    path.lineTo(-_halfNodeSize + _halfEdgeThickness,
        _halfNodeSize - _edgeSize + _halfEdgeThickness);
    return path;
  }();

  static final Path _insidePath = () {
    final insidePath = Path();
    insidePath.moveTo(-_edgeThickness, -_edgeThickness);
    insidePath.lineTo(_edgeThickness, -_edgeThickness);
    insidePath.lineTo(_edgeThickness, _edgeThickness);
    insidePath.lineTo(-_edgeThickness, _edgeThickness);
    insidePath.close();

    return insidePath;
  }();

  @override
  void removedFromStage(Stage stage) {
    cancelBoundsChanged();
    super.removedFromStage(stage);
  }

  @override
  void addSnapTarget(SnappingAxes axes) {
    axes.addVec(AABB.center(Vec2D(), aabb));
  }

  @override
  void addedToStage(Stage stage) {
    super.addedToStage(stage);
    computeBounds();
  }
}
