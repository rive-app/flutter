import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/transform_components.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/shapes/paint/fill.dart';
import 'package:rive_core/shapes/paint/solid_color.dart';
import 'package:rive_core/shapes/parametric_path.dart';
import 'package:rive_core/shapes/path_composer.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:rive_core/shapes/path.dart' as core;
import 'package:rive_core/transform_component.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/rive/stage/stage_drawable.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/auto_tool.dart';
import 'package:rive_editor/rive/stage/tools/create_tool.dart';
import 'package:rive_editor/rive/stage/tools/stage_tool_tip.dart';
import 'package:rive_editor/widgets/theme.dart';
import 'package:utilities/utilities.dart';

abstract class ShapeTool extends CreateTool {
  @override
  Iterable<PackedIcon> get cursorName => PackedIcon.cursorAdd;

  Vec2D _startWorldMouse;
  Vec2D _startLocalMouse;
  Vec2D _start, _end, _cursor;
  bool _dragging = false;

  ParametricPath makePath();
  String get shapeName;
  Shape _shape;
  ParametricPath _path;

  Artboard _currentArtboard;

  final StageToolTip _tip = StageToolTip();

  @override
  bool activate(Stage stage) {
    if (!super.activate(stage)) {
      return false;
    }
    // Start listening for edit mode changes
    _symmetricDrawChanged();
    ShortcutAction.symmetricDraw.addListener(_symmetricDrawChanged);
    stage.file.addActionHandler(_handleAction);
    return true;
  }

  @override
  void deactivate() {
    super.deactivate();
    ShortcutAction.symmetricDraw.removeListener(_symmetricDrawChanged);
    stage.file.removeActionHandler(_handleAction);
  }

  final Mat2D _parentWorldInverse = Mat2D();
  final Mat2D _parentWorld = Mat2D();

  @override
  void startDrag(Iterable<StageItem> selection, Artboard activeArtboard,
      Vec2D worldMouse) {
    super.startDrag(selection, activeArtboard, worldMouse);
    assert(activeArtboard != null, 'Shape tool must have an active artboard.');
    _dragging = true;
    _end = _start = null;
    // Create a Shape and place it at the world location.
    _startWorldMouse = Vec2D.clone(worldMouse);

    // Track the artboard we're using for this operation (in case it changes via
    // a shortcut or something while the drag operation is continuing).
    _currentArtboard = activeArtboard;

    var topComponents = tops<Component>(selection
        .where((item) => item.component is Component)
        .map((item) => item.component as Component)
        .toSet());

    var parent = topComponents.isNotEmpty
        ? topComponents.first.parent ?? activeArtboard
        : activeArtboard;

    if (parent is TransformComponent) {
      Mat2D.copy(_parentWorld, parent.worldTransform);
      if (!Mat2D.invert(_parentWorldInverse, parent.worldTransform)) {
        Mat2D.identity(_parentWorldInverse);
      }
    } else {
      Mat2D.identity(_parentWorldInverse);
      Mat2D.identity(_parentWorld);
    }
    // Get the mouse in parent space.
    var localMouse =
        Vec2D.transformMat2D(Vec2D(), worldMouse, _parentWorldInverse);

    _shape = makeShape(parent, (_path = makePath()))
      ..name = shapeName
      ..x = localMouse[0]
      ..y = localMouse[1];
  }

  static Shape makeShape(ContainerComponent parent, core.Path path,
      {bool addToParent = true}) {
    final file = parent.context;
    Shape shape;
    file.batchAdd(() {
      shape = Shape();

      final composer = PathComposer();
      final solidColor = SolidColor();
      final fill = Fill()..name = 'Fill 1';

      file.addObject(shape);
      file.addObject(fill);
      file.addObject(solidColor);
      file.addObject(composer);
      if (path.context == null) {
        file.addObject(path);
      }

      // Let's build up the shape hierarchy:
      // Artboard
      // │
      // └─▶ Shape
      //       │
      //       ├─▶ Fill
      //       │     │
      //       │     └─▶ SolidColor
      //       │
      //       ├─▶ PathComposer
      //       │
      //       └─▶ Path
      shape.appendChild(path);
      shape.appendChild(composer);
      shape.appendChild(fill);
      fill.appendChild(solidColor);
      if (addToParent) {
        parent.prependChild(shape);
      }
    });
    return shape;
  }

  @override
  void endDrag() {
    if (_shape != null) {
      // Operation complete, let's select the shape. #970 #1030
      stage.file.select(_shape.stageItem);
    }
    _shape = null;
    _dragging = false;
    _end = _start = null;
  }

  @override
  void updateDrag(Vec2D worldMouse) {
    if (ShortcutAction.symmetricDraw.value) {
      final maxChange = max(
        (_startWorldMouse[0] - worldMouse[0]).abs(),
        (_startWorldMouse[1] - worldMouse[1]).abs(),
      );
      final x1 = (_startWorldMouse[0] < worldMouse[0])
          ? _startWorldMouse[0]
          : _startWorldMouse[0] - maxChange;
      final y1 = (_startWorldMouse[1] < worldMouse[1])
          ? _startWorldMouse[1]
          : _startWorldMouse[1] - maxChange;
      _start = Vec2D.fromValues(
        x1,
        y1,
      );
      _end = Vec2D.fromValues(
        _start[0] + maxChange,
        _start[1] + maxChange,
      );
    } else {
      _start = Vec2D.fromValues(
        min(_startWorldMouse[0], worldMouse[0]),
        min(_startWorldMouse[1], worldMouse[1]),
      );
      _end = Vec2D.fromValues(
        max(_startWorldMouse[0], worldMouse[0]),
        max(_startWorldMouse[1], worldMouse[1]),
      );
    }

    _cursor = Vec2D.clone(worldMouse);

    _shape.x = _start[0];
    _shape.y = _start[1];

    var worldTransform = Mat2D();
    worldTransform[4] = _shape.x;
    worldTransform[5] = _shape.y;

    var local = Mat2D();
    Mat2D.multiply(local, _parentWorldInverse, worldTransform);
    var components = TransformComponents();
    Mat2D.decompose(local, components);
    _shape.scaleX = components.scaleX;
    _shape.scaleY = components.scaleY;
    _shape.rotation = components.rotation;
    _shape.x = components.x;
    _shape.y = components.y;

    _path.width = _end[0] - _start[0];
    _path.height = _end[1] - _start[1];
    _path.x = _path.width / 2;
    _path.y = _path.height / 2;

    _tip.text =
        '${(_end[0] - _start[0]).round()}x${(_end[1] - _start[1]).round()}';
  }

  @override
  void draw(Canvas canvas, StageDrawPass drawPass) {
    // happens when we first start dragging.
    if (_start == null) {
      return;
    }

    // Compute obb of the path to draw in screen space.

    var path = StageItem.makeBoundsPath(
        Mat2D.multiply(Mat2D(), stage.viewTransform,
            _path.artboard.transform(_path.pathTransform)),
        _path.preciseComputeBounds(
          null,
        ));
    // // We do a little extra work here to make sure that skewed bounds look
    // // correct too.

    // var startLocal = Vec2D.transformMat2D(Vec2D(), _start, _parentWorldInverse);
    // var endLocal = Vec2D.transformMat2D(Vec2D(), _end, _parentWorldInverse);
    // // Now build the local 4 corners and get those back into world.
    // var topLef = Vec2D.transformMat2D(Vec2D(), _start, _parentWorldInverse);

    // Get in screen space.
    var start = Vec2D.clone(stageWorldSpace(_currentArtboard, _start));
    var end = Vec2D.clone(stageWorldSpace(_currentArtboard, _end));
    var cursor = Vec2D.clone(stageWorldSpace(_currentArtboard, _cursor));
    Vec2D.transformMat2D(start, start, stage.viewTransform);
    Vec2D.transformMat2D(end, end, stage.viewTransform);
    Vec2D.transformMat2D(cursor, cursor, stage.viewTransform);
    // Get bounds in
    canvas.drawPath(
        path,

        // canvas.drawRect(
        //     Rect.fromLTRB(
        //       start[0],
        //       start[1],
        //       end[0],
        //       end[1],
        //     ),
        Paint()
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke
          ..color = RiveThemeData().colors.shapeBounds);

    _tip.paint(canvas, Offset(cursor[0] + 10, cursor[1] + 10));
  }

  void _symmetricDrawChanged() {
    if (lastWorldMouse != null && _shape != null) {
      updateDrag(lastWorldMouse);
    }
  }

  /// Handle any shortcuts that affect the auto tool
  /// In this case, if escape is hit before dragging starts,
  /// then switch to the auto tool
  bool _handleAction(ShortcutAction action) {
    switch (action) {
      case ShortcutAction.cancel:
        // Ignore cancel if in the middle of a drag
        if (!_dragging) {
          // Switch to the auto tool
          stage.tool = AutoTool.instance;
        }
        return true;
      default:
        return false;
    }
  }
}
