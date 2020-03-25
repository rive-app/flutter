import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_editor/rive/stage/aabb_tree.dart';

import 'stage.dart';

extension StageItemComponent on Component {
  StageItem get stageItem => userData as StageItem;
  set stageItem(StageItem value) => userData = value;
}

abstract class StageItem<T> extends SelectableItem {
  static const double strokeWidth = 2;
  static Paint selectedPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth
    ..color = const Color(0xFF57A5E0);

  T _component;
  T get component => _component;

  Stage _stage;
  Stage get stage => _stage;

  int get drawOrder => 1;

  int visTreeProxy = nullNode;

  bool initialize(T component) {
    _component = component;
    return true;
  }

  /// Perform a higher fidelity check for worldMouse hit. If this object doesn't
  /// have a narrow-phase hit detection, just return true to use the AABB.
  bool hitHiFi(Vec2D worldMouse) => true;

  /// Override this to temporarily hide items. This shouldn't be used to
  /// permanently hide an item. If an item is no longer necessary it should be
  /// removed from the stage.
  bool get isVisible => true;

  /// Override this to prevent this item from being clicked on.
  bool get isSelectable => isVisible;

  @mustCallSuper
  void addedToStage(Stage stage) {
    _stage = stage;
  }

  void removedFromStage(Stage stage) {
    _stage = null;
  }

  @override
  void onHoverChanged(bool value) {
    // No longer hovered?
    if (value) {
      _stage?.hoverItem = this;
    } else if (_stage?.hoverItem == this) {
      _stage?.hoverItem = null;
    }

    _stage?.markNeedsAdvance();
  }

  @override
  void onSelectedChanged(bool value) {
    _stage?.markNeedsAdvance();
  }

  /// Provide an aabb for this stage item.
  AABB get aabb;

  void draw(Canvas canvas) {}
}

AABB obbToAABB(AABB obb, Mat2D world) {
  Vec2D p1 = Vec2D.fromValues(obb[0], obb[1]);
  Vec2D p2 = Vec2D.fromValues(obb[2], obb[1]);
  Vec2D p3 = Vec2D.fromValues(obb[2], obb[3]);
  Vec2D p4 = Vec2D.fromValues(obb[0], obb[3]);

  Vec2D.transformMat2D(p1, p1, world);
  Vec2D.transformMat2D(p2, p2, world);
  Vec2D.transformMat2D(p3, p3, world);
  Vec2D.transformMat2D(p4, p4, world);

  return AABB.fromValues(
      min(p1[0], min(p2[0], min(p3[0], p4[0]))),
      min(p1[1], min(p2[1], min(p3[1], p4[1]))),
      max(p1[0], max(p2[0], max(p3[0], p4[0]))),
      max(p1[1], max(p2[1], max(p3[1], p4[1]))));
}
