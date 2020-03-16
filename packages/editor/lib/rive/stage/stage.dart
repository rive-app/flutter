import 'dart:math';

import 'package:core/debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:rive_core/artboard.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/shapes/ellipse.dart';
import 'package:rive_core/shapes/points_path.dart';
import 'package:rive_core/shapes/rectangle.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:rive_core/shapes/straight_vertex.dart';
import 'package:rive_core/shapes/triangle.dart';

import 'package:rive_editor/constants.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:rive_editor/rive/stage/advancer.dart';
import 'package:rive_editor/rive/stage/items/stage_artboard.dart';
import 'package:rive_editor/rive/stage/items/stage_node.dart';
import 'package:rive_editor/rive/stage/items/stage_path.dart';
import 'package:rive_editor/rive/stage/items/stage_vertex.dart';
import 'package:rive_editor/rive/stage/tools/clickable_tool.dart';
import 'package:rive_editor/rive/stage/tools/draggable_tool.dart';
import 'package:rive_editor/rive/stage/tools/moveable_tool.dart';
import 'package:rive_editor/rive/stage/aabb_tree.dart';
import 'package:rive_editor/rive/stage/items/stage_ellipse.dart';
import 'package:rive_editor/rive/stage/items/stage_rectangle.dart';
import 'package:rive_editor/rive/stage/items/stage_shape.dart';
import 'package:rive_editor/rive/stage/items/stage_triangle.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/stage_tool.dart';

enum AxisCheckState { local, parent, world }

typedef _ItemFactory = StageItem Function();

abstract class StageDelegate {
  void stageNeedsAdvance();
  void stageNeedsRedraw();
}

/// Some notes about how the Stage works and future plans for it here:
/// https://www.notion.so/Stage-65da45b819b249839e2ca0bb659c6a01
class Stage extends Debouncer {
  static const double _minZoom = 0.1;
  static const double _maxZoom = 8;

  /// Reference to the Rive context for the app.
  final Rive rive;

  /// Reference to the current riveFile this stage represents.
  final RiveFile riveFile;

  final Mat2D _viewTransform = Mat2D();
  final Mat2D _inverseViewTransform = Mat2D();
  final Vec2D _lastMousePosition = Vec2D();
  final Set<Advancer> _advancingItems = {};
  // bool _isRightMouseDown = false;
  double _rightMouseMoveAccum = 0;
  Mat2D get inverseViewTransform => _inverseViewTransform;
  double _viewportWidth = 0, _viewportHeight = 0;
  Mat2D get viewTransform => _viewTransform;
  double get viewportWidth => _viewportWidth;
  double get viewportHeight => _viewportHeight;
  final List<StageItem> _visibleItems = [];
  final Vec2D _viewTranslation = Vec2D();
  double _viewZoom = 1;
  double get viewZoom => _viewZoom;
  final Vec2D _viewTranslationTarget = Vec2D();
  double _viewZoomTarget = 1;
  Vec2D _worldMouse = Vec2D();
  bool _mouseDownSelected = false;
  EditMode activeEditMode = EditMode.normal;

  StageDelegate _delegate;
  final ValueNotifier<StageTool> toolNotifier = ValueNotifier<StageTool>(null);
  StageTool _activeTool;
  StageTool get tool => toolNotifier.value;
  set tool(StageTool value) {
    if (toolNotifier.value == value) {
      return;
    }
    if (value.activate(this)) {
      toolNotifier.value = value;
    }
    // Tools that are Moveable (e.g. PenTool) are activated as soon as
    // they are set.
    if (value is MoveableTool) {
      _activeTool = value;
      (_activeTool as MoveableTool).mousePosition = _worldMouse;
    } else {
      _activeTool = null;
    }
    _activeTool = value is MoveableTool ? value : null;
  }

  // Joints freezed flag
  final ValueNotifier<bool> freezeJointsNotifier = ValueNotifier<bool>(false);
  bool get freezeJoints => freezeJointsNotifier.value;
  set freezeJoints(bool value) {
    if (freezeJointsNotifier.value != value) {
      freezeJointsNotifier.value = value;
    }
  }

  // Images freezed flag
  final ValueNotifier<bool> freezeImagesNotifier = ValueNotifier<bool>(false);
  bool get freezeImages => freezeImagesNotifier.value;
  set freezeImages(bool value) {
    if (freezeImagesNotifier.value != value) {
      freezeImagesNotifier.value = value;
    }
  }

  // Axis check state
  final ValueNotifier<AxisCheckState> axisCheckNotifier =
      ValueNotifier<AxisCheckState>(AxisCheckState.local);
  AxisCheckState get axisCheck => axisCheckNotifier.value;
  set axisCheck(AxisCheckState value) {
    if (axisCheckNotifier.value != value) {
      axisCheckNotifier.value = value;
    }
  }

  // Zoom level notifier
  final ValueNotifier<int> zoomLevelNotifier = ValueNotifier<int>(100);
  int get zoomLevel => zoomLevelNotifier.value;
  set zoomLevel(int value) {
    if (zoomLevelNotifier.value != value) {
      zoomLevelNotifier.value = value;
      print('Setting zoom level to $value');
    }
  }

  // Resolution notifier
  final ValueNotifier<int> resolutionNotifier = ValueNotifier<int>(100);
  int get resolution => resolutionNotifier.value;
  set resolution(int value) {
    if (resolutionNotifier.value != value) {
      resolutionNotifier.value = value;
      print('Setting resolution to $value');
    }
  }

  // Show images flag
  final ValueNotifier<bool> showImagesNotifier = ValueNotifier<bool>(false);
  bool get showImages => showImagesNotifier.value;
  set showImages(bool value) {
    if (showImagesNotifier.value != value) {
      showImagesNotifier.value = value;
    }
  }

  // Show image contour flag
  final ValueNotifier<bool> showContourNotifier = ValueNotifier<bool>(false);
  bool get showContour => showContourNotifier.value;
  set showContour(bool value) {
    if (showContourNotifier.value != value) {
      showContourNotifier.value = value;
    }
  }

  // Show bones flag
  final ValueNotifier<bool> showBonesNotifier = ValueNotifier<bool>(false);
  bool get showBones => showBonesNotifier.value;
  set showBones(bool value) {
    if (showBonesNotifier.value != value) {
      showBonesNotifier.value = value;
    }
  }

  // Show effects flag
  final ValueNotifier<bool> showEffectsNotifier = ValueNotifier<bool>(false);
  bool get showEffects => showEffectsNotifier.value;
  set showEffects(bool value) {
    if (showEffectsNotifier.value != value) {
      showEffectsNotifier.value = value;
    }
  }

  // Show rulers flag
  final ValueNotifier<bool> showRulersNotifier = ValueNotifier<bool>(false);
  bool get showRulers => showRulersNotifier.value;
  set showRulers(bool value) {
    if (showRulersNotifier.value != value) {
      showRulersNotifier.value = value;
    }
  }

  // Show grid flag
  final ValueNotifier<bool> showGridNotifier = ValueNotifier<bool>(false);
  bool get showGrid => showGridNotifier.value;
  set showGrid(bool value) {
    if (showGridNotifier.value != value) {
      showGridNotifier.value = value;
    }
  }

  // Show Axis flag
  final ValueNotifier<bool> showAxisNotifier = ValueNotifier<bool>(false);
  bool get showAxis => showAxisNotifier.value;
  set showAxis(bool value) {
    if (showAxisNotifier.value != value) {
      showAxisNotifier.value = value;
    }
  }

  void clearDelegate(StageDelegate value) {
    if (_delegate == value) {
      _delegate = null;
    }
  }

  void delegate(StageDelegate value) {
    _delegate = value;
  }

  void markNeedsRedraw() => _delegate?.stageNeedsRedraw?.call();

  bool setViewport(double width, double height) {
    if (width == _viewportWidth && height == _viewportHeight) {
      return false;
    }
    _viewportWidth = width;
    _viewportHeight = height;
    markNeedsAdvance();
    return true;
  }

  void zoomTo(double x, double y, double scale) {
    double zoom = scale.clamp(_minZoom, _maxZoom).toDouble();
    double zoomDelta = zoom / _viewZoomTarget;
    _viewZoomTarget = zoom;

    double ox = x - _viewTranslationTarget[0];
    double oy = y - _viewTranslationTarget[1];

    double ox2 = ox * zoomDelta;
    double oy2 = oy * zoomDelta;

    _viewTranslationTarget[0] += ox - ox2;
    _viewTranslationTarget[1] += oy - oy2;
    markNeedsAdvance();
  }

  void mouseWheel(double x, double y, double dx, double dy) {
    _lastMousePosition[0] = x;
    _lastMousePosition[1] = y;
    zoomTo(x, y, _viewZoomTarget - dy / 30);
  }

  StageItem _hoverItem;
  StageItem get hoverItem => _hoverItem;
  set hoverItem(StageItem value) {
    if (value == _hoverItem) {
      return;
    }
    var last = _hoverItem;
    _hoverItem = value;
    last?.isHovered = false;

    markNeedsAdvance();
  }

  void _computeWorldMouse(double localX, double localY) {
    _worldMouse = Vec2D.transformMat2D(
        Vec2D(), Vec2D.fromValues(localX, localY), _inverseViewTransform);
  }

  void mouseMove(int button, double x, double y) {
    _computeWorldMouse(x, y);

    rive.file.value.cursorMoved(_worldMouse[0], _worldMouse[1]);

    AABB viewAABB = AABB.fromValues(
        _worldMouse[0], _worldMouse[1], _worldMouse[0] + 1, _worldMouse[1] + 1);
    StageItem hover;
    visTree.query(viewAABB, (int proxyId, StageItem item) {
      if (item.isSelectable &&
          item.drawOrder >= (hover?.drawOrder ?? 0) &&
          item.hitHiFi(_worldMouse)) {
        hover = item;
      }
      return true;
    });
    hover?.isHovered = true;
    if (hover == null) {
      hoverItem = null;
    }

    _lastMousePosition[0] = x;
    _lastMousePosition[1] = y;

    if (_activeTool is MoveableTool) {
      (_activeTool as MoveableTool).updateMove(_worldMouse);
      markNeedsAdvance();
    }
  }

  void mouseDown(int button, double x, double y) {
    _computeWorldMouse(x, y);
    _lastMousePosition[0] = x;
    _lastMousePosition[1] = y;

    switch (button) {
      case 1:
        if (_activeTool is ClickableTool) {
          var artboard = activeArtboard;

          (_activeTool as ClickableTool)
              .onClick(artboard, tool.mouseWorldSpace(artboard, _worldMouse));
        } else {
          if (_hoverItem != null) {
            _mouseDownSelected = true;
            rive.select(_hoverItem);
          } else {
            _mouseDownSelected = false;
          }
        }

        break;
      default:
    }
  }

  void mouseDrag(int button, double x, double y) {
    _computeWorldMouse(x, y);
    rive.file.value.cursorMoved(_worldMouse[0], _worldMouse[1]);
    switch (button) {
      case 2:
        double dx = x - _lastMousePosition[0];
        double dy = y - _lastMousePosition[1];

        _rightMouseMoveAccum += sqrt(dx * dx + dy * dy);
        _viewTranslationTarget[0] += dx;
        _viewTranslationTarget[1] += dy;

        _lastMousePosition[0] = x;
        _lastMousePosition[1] = y;
        markNeedsAdvance();
        break;
      case 1:
        // [tool] is set to its value in the tool setter.
        if (tool is DraggableTool) {
          var artboard = activeArtboard;
          var worldMouse = tool.mouseWorldSpace(artboard, _worldMouse);

          // [_activeTool] is [null] before dragging operation starts.
          if (_activeTool == null) {
            _activeTool = tool;
            _activeTool.setEditMode(activeEditMode);
            (_activeTool as DraggableTool).startDrag(
                rive.selection.items.whereType<StageItem>(),
                artboard,
                worldMouse);
          } else {
            // [_activeTool] dragging operation has already started, so we
            // need to progress.
            (_activeTool as DraggableTool).drag(worldMouse);
          }
        }
        break;
    }
  }

  void mouseUp(int button, double x, double y) {
    _computeWorldMouse(x, y);

    _lastMousePosition[0] = x;
    _lastMousePosition[1] = y;
    if (button == 2 && _rightMouseMoveAccum < 5) {
      // show a popup.
    }

    if (_activeTool is DraggableTool && _activeTool != null) {
      (_activeTool as DraggableTool).endDrag();
      _activeTool = null;
      rive.file.value.captureJournalEntry();
    } else if (!_mouseDownSelected) {
      rive.selection.clear();
    }
  }

  void mouseExit(int button, double x, double y) {
    _computeWorldMouse(x, y);
    _worldMouse = null;
    hoverItem = null;
    if (_activeTool is MoveableTool) {
      (_activeTool as MoveableTool).onExit();
    }
  }

  // TODO: Get actual active artboard, not just the first one.
  Artboard get activeArtboard {
    if (riveFile.artboards.isEmpty) {
      return null;
    }
    return riveFile.artboards.first;
  }

  final AABBTree<StageItem> visTree = AABBTree<StageItem>(padding: 0);

  Stage(this.rive, this.riveFile) {
    for (final object in riveFile.objects) {
      if (object is Component) {
        initComponent(object);
      }
    }
  }

  void markNeedsAdvance() {
    if (!_needsAdvance) {
      _needsAdvance = true;
      rive.markNeedsAdvance();
      _delegate?.stageNeedsAdvance();
    }
  }

  /// Register a Core object with the stage.
  void initComponent(Component component) {
    var stageItemFactory = _factories[component.coreType];
    // We used to assert here and not allow null stageItems for components. We
    // used to do this because even though some components may not need a
    // stageItem, we still wanted them to be selectable in the hierarchy.
    // Hierarchy selections. However, there are cases where we'll want
    // components to not have a stage presence and not be selectable at all
    // (like the PathComposer).
    if (stageItemFactory != null) {
      var stageItem = stageItemFactory();
      if (stageItem != null && stageItem.initialize(component)) {
        component.stageItem = stageItem;
        addItem(stageItem);
      }
    }
  }

  void updateBounds(StageItem item) {
    visTree.placeProxy(item.visTreeProxy, item.aabb);
    markNeedsAdvance();
  }

  bool addItem(StageItem item) {
    assert(item != null);
    if (item.visTreeProxy != nullNode) {
      return false;
    }

    item.visTreeProxy = visTree.createProxy(item.aabb, item);
    item.addedToStage(this);
    markNeedsAdvance();
    if (item is Advancer) {
      _advancingItems.add(item as Advancer);
    }
    return true;
  }

  bool removeItem(StageItem item) {
    assert(item != null);
    if (item.visTreeProxy == nullNode) {
      return false;
    }

    visTree.destroyProxy(item.visTreeProxy);
    item.visTreeProxy = nullNode;
    item.removedFromStage(this);
    markNeedsAdvance();
    if (item is Advancer) {
      _advancingItems.remove(item as Advancer);
    }
    return true;
  }

  /// Clear out all stage items. Normally called when the file is also wiped.
  void wipe() {
    _visibleItems.clear();
    visTree.clear();
    hoverItem = null;
  }

  void dispose() {}

  void _onFileChanged() {}

  bool get shouldAdvance => _needsAdvance || needsDebounce;
  bool _needsAdvance = true;

  void advance(double elapsed) {
    debounceAll();

    _needsAdvance = false;
    for (final advancers in _advancingItems) {
      if (advancers.advance(elapsed)) {
        _needsAdvance = true;
      }
    }

    double ds = _viewZoomTarget - _viewZoom;
    double dx = _viewTranslationTarget[0] - _viewTranslation[0];
    double dy = _viewTranslationTarget[1] - _viewTranslation[1];

    double factor = min(1, elapsed * 30);

    if (ds.abs() > 0.00001) {
      _needsAdvance = true;
      ds *= factor;
    }
    if (dx.abs() > 0.01) {
      _needsAdvance = true;
      dx *= factor;
    }
    if (dy.abs() > 0.01) {
      _needsAdvance = true;
      dy *= factor;
    }

    _viewZoom += ds;
    _viewTranslation[0] += dx;
    _viewTranslation[1] += dy;

    Mat2D view = viewTransform;
    view[0] = _viewZoom;
    view[3] = _viewZoom;
    view[4] = _viewTranslation[0];
    view[5] = _viewTranslation[1];

    // Take this opportunity to update any stageItem paints that rely on the
    // zoom level.
    StageItem.selectedPaint.strokeWidth = StageItem.strokeWidth / _viewZoom;
  }

  void paint(PaintingContext context, Offset offset, Size size) {
    Mat2D.invert(_inverseViewTransform, _viewTransform);
    var viewAABB = obbToAABB(
        AABB.fromValues(0, 0, _viewportWidth, _viewportHeight),
        _inverseViewTransform);

    _visibleItems.clear();
    visTree.query(viewAABB, (int proxyId, StageItem item) {
      if (item.isVisible) {
        _visibleItems.add(item);
      }
      return true;
    });

    var canvas = context.canvas;
    canvas.save();
    // Translate to widget space
    canvas.clipRect(offset & size);
    canvas.translate(offset.dx, offset.dy);
    canvas.save();

    // Transform to world space
    canvas.transform(viewTransform.mat4);

    _visibleItems.sort((StageItem a, StageItem b) => a.drawOrder - b.drawOrder);

    for (final StageItem item in _visibleItems) {
      item.paint(canvas);
    }

    canvas.restore();

    // Widget space
    _activeTool?.paint(canvas);
    canvas.restore();
  }

  final Map<int, _ItemFactory> _factories = {
    ArtboardBase.typeKey: () => StageArtboard(),
    NodeBase.typeKey: () => StageNode(),
    ShapeBase.typeKey: () => StageShape(),
    EllipseBase.typeKey: () => StageEllipse(),
    RectangleBase.typeKey: () => StageRectangle(),
    TriangleBase.typeKey: () => StageTriangle(),
    PointsPathBase.typeKey: () => StagePath(),
    StraightVertexBase.typeKey: () => StageVertex(),
  };

  @override
  void onNeedsDebounce() => markNeedsAdvance();

  void updateEditMode(EditMode editMode) {
    activeEditMode = editMode;
    if (_activeTool != null && _activeTool is DraggableTool) {
      _activeTool.setEditMode(editMode);
    }
  }

  void toggleEditMode() {
    // TODO: Try to get the StagePaths or the StageShapes from the current selection,
    // and set it the current editing shape.
  }
}
