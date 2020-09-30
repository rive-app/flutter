import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:rive_core/bounds_delegate.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
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
    with BoundsDelegate, StageTransformableComponent<Node> {
  @override
  ValueNotifier<bool> get isShownNotifier => stage.showNodesNotifier;

  @override
  Iterable<StageDrawPass> get drawPasses => [
        if (obb == null)
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

  bool get shouldDrawBounds {
    return obb != null && hasSelectionFlags && _boundsValid;
  }

  /// Force set some draw order that supersedes the shape draw order so nodes
  /// always win over shapes.
  @override
  int get drawOrder => drawPasses.isEmpty ? 11 : super.drawOrder;

  @override
  bool intersectsRect(Float32List rectPoly) => true;

  bool isExpanded = false;

  @override
  bool get isHoverSelectable =>
      !isExpanded &&
      (display == StageNodeDisplay.node || !ShortcutAction.deepClick.value) &&
      super.isHoverSelectable;

  Iterable<StageNode> get allParentNodes {
    List<StageNode> nodes = [this];
    for (var p = component.parent; p != null; p = p.parent) {
      if (p.stageItem is StageNode) {
        nodes.add(p.stageItem as StageNode);
      }
    }
    return nodes;
  }

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
  int compareDrawOrderTo(StageItem other) {
    if (other is StageNode) {
      return other._hierarchyDepth.compareTo(_hierarchyDepth);
    } else {
      return super.compareDrawOrderTo(other);
    }
  }

  Timer _updateBoundsTimer;
  int _hierarchyDepth = 0;

  void _computeBounds() {
    if (component?.artboard == null) {
      return;
    }
    // Compute hierarchy depth to use that to sort against other stage nodes
    // (stage nodes higher in the hierarchy will hit first).
    _hierarchyDepth = 0;
    for (ContainerComponent p = component; p != null; p = p.parent) {
      _hierarchyDepth++;
    }

    var artboard = component.artboard;
    var worldTransform = component.worldTransform;
    AABB accumulatedBounds;
    component.forEachChild((component) {
      // When we have images we may want to have a generic interface for getting
      // the bounds, but for now we only have shapes.
      if (component.coreType == ShapeBase.typeKey) {
        var shape = component as Shape;
        var bounds = shape.computeBounds(worldTransform);
        if (accumulatedBounds == null) {
          accumulatedBounds = bounds;
        } else {
          AABB.combine(accumulatedBounds, accumulatedBounds, bounds);
        }
      }
      return true;
    });

    if (accumulatedBounds == null ||
        accumulatedBounds.isEmpty ||
        accumulatedBounds.area == 0) {
      // No accmulated bounds, show the node icon and use its bounds.
      obb = null;
      _hierarchyDepth = -1;
      aabb = AABB
          .fromValues(
              component.worldTransform[4] - _halfNodeSize,
              component.worldTransform[5] - _halfNodeSize,
              component.worldTransform[4] + _halfNodeSize,
              component.worldTransform[5] + _halfNodeSize)
          .translate(component.artboard.originWorld);
    } else {
      // We won't show the icon as we have bounds,

      // accumulatedBounds is in local node space so convert it to world for the
      // AABB.
      aabb = accumulatedBounds.transform(artboard.transform(worldTransform));

      // Store an OBB so we can draw and use that for accurate hit detection.
      obb = OBB(
        bounds: accumulatedBounds,
        transform: artboard.transform(component.worldTransform),
      );
    }
    _boundsValid = true;
  }

  bool _boundsValid = false;
  @override
  void boundsChanged() {
    _boundsValid = false;
    _updateBoundsTimer?.cancel();
    _updateBoundsTimer = Timer(
        Duration(milliseconds: 50 + Random().nextInt(200)), _computeBounds);
  }

  @override
  void removedFromStage(Stage stage) {
    _updateBoundsTimer?.cancel();
    super.removedFromStage(stage);
  }

  @override
  void addSnapTarget(SnappingAxes axes) {
    axes.addVec(AABB.center(Vec2D(), aabb));
  }

  @override
  void addedToStage(Stage stage) {
    super.addedToStage(stage);
    _computeBounds();
  }
}
