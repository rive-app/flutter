import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:core/debounce.dart';
import 'package:cursor/cursor_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/shapes/ellipse.dart';
import 'package:rive_core/shapes/paint/gradient_stop.dart';
import 'package:rive_core/shapes/paint/radial_gradient.dart';
import 'package:rive_core/shapes/points_path.dart';
import 'package:rive_core/shapes/rectangle.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:rive_core/shapes/straight_vertex.dart';
import 'package:rive_core/shapes/triangle.dart';
import 'package:rive_editor/constants.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/rive/stage/aabb_tree.dart';
import 'package:rive_editor/rive/stage/advancer.dart';
import 'package:rive_editor/rive/stage/items/stage_artboard.dart';
import 'package:rive_editor/rive/stage/items/stage_ellipse.dart';
import 'package:rive_editor/rive/stage/items/stage_gradient_stop.dart';
import 'package:rive_editor/rive/stage/items/stage_linear_gradient.dart';
import 'package:rive_editor/rive/stage/items/stage_node.dart';
import 'package:rive_editor/rive/stage/items/stage_path.dart';
import 'package:rive_editor/rive/stage/items/stage_radial_gradient.dart';
import 'package:rive_editor/rive/stage/items/stage_rectangle.dart';
import 'package:rive_editor/rive/stage/items/stage_shape.dart';
import 'package:rive_editor/rive/stage/items/stage_triangle.dart';
import 'package:rive_editor/rive/stage/items/stage_vertex.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/clickable_tool.dart';
import 'package:rive_editor/rive/stage/tools/draggable_tool.dart';
import 'package:rive_editor/rive/stage/tools/late_draw_stage_tool.dart';
import 'package:rive_editor/rive/stage/tools/moveable_tool.dart';
import 'package:rive_editor/rive/stage/tools/stage_tool.dart';
import 'package:rive_core/shapes/paint/linear_gradient.dart';
import 'package:rive_editor/rive/stage/tools/transforming_tool.dart';
import 'package:rive_editor/widgets/common/cursor_icon.dart';

typedef CustomSelectionHandler = bool Function(StageItem);

enum AxisCheckState { local, parent, world }

typedef _ItemFactory = StageItem Function();

abstract class StageDelegate {
  void stageNeedsAdvance();
  void stageNeedsRedraw();
  Future<ui.Image> rasterize();
  Cursor customCursor;
}

abstract class LateDrawViewDelegate {
  void markNeedsPaint();
  LateDrawStageTool tool;
}

/// Hacky way to do friend class access in Dart by using an interface with
/// private fields the Stage can write to. This is for storing and handling
/// object specific fields that should not be exposed to the system and are
/// really only for the Stage to handle. Removing them from the StageItem helps
/// avoid confusion for people implementing custom StageItems.
class StageItemFriend {
  int _visTreeProxy = nullNode;
}

/// Some notes about how the Stage works and future plans for it here:
/// https://www.notion.so/Stage-65da45b819b249839e2ca0bb659c6a01
class Stage extends Debouncer {
  static const double minZoom = 0.1;
  static const double maxZoom = 8;

  /// Reference to the file that owns this stage.
  final OpenFileContext file;

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
  Offset localMouse = Offset.zero;
  bool _mouseDownSelected = false;
  EditMode activeEditMode = EditMode.normal;
  bool _isHidingCursor = false;
  int _hoverOffsetIndex = -1;

  CustomSelectionHandler customSelectionHandler;

  /// We store these two separtely to avoid contention with how they are
  /// activated/disabled.
  CursorInstance _rightClickHandCursor;
  CursorInstance _panHandCursor;

  bool _isPanning = false;

  // Clear the selection handler only if it was a previously set one.
  bool clearSelectionHandler(CustomSelectionHandler handler) {
    if (customSelectionHandler == handler) {
      customSelectionHandler = null;
      return true;
    }
    return false;
  }

  LateDrawViewDelegate lateDrawDelegate;

  StageDelegate _delegate;
  final ValueNotifier<StageTool> toolNotifier = ValueNotifier<StageTool>(null);
  StageTool _activeTool;
  StageTool get tool => toolNotifier.value;
  set tool(StageTool value) {
    if (toolNotifier.value == value) {
      return;
    }
    if (value.activate(this)) {
      toolNotifier.value?.deactivate();
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

    // Update the late draw render object to know which tool it should be
    // delegating draw operations for (if any).
    if (value is LateDrawStageTool) {
      lateDrawDelegate?.tool = value as LateDrawStageTool;
    } else {
      lateDrawDelegate?.tool = null;
    }
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
  final ValueNotifier<double> zoomLevelNotifier = ValueNotifier<double>(1);
  double get zoomLevel => zoomLevelNotifier.value;
  set zoomLevel(double value) {
    if (zoomLevelNotifier.value != value) {
      zoomTo(_viewportWidth / 2, _viewportHeight / 2, value);
    }
  }

  // Resolution notifier
  final ValueNotifier<double> resolutionNotifier = ValueNotifier<double>(1);
  double get resolution => resolutionNotifier.value;
  set resolution(double value) {
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

  StageDelegate get delegate => _delegate;
  void delegateTo(StageDelegate value) {
    if (value == _delegate) {
      return;
    }
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
    double zoom = scale.clamp(minZoom, maxZoom).toDouble();
    double zoomDelta = zoom / _viewZoomTarget;
    _viewZoomTarget = zoom;
    zoomLevelNotifier.value = zoom;

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
    if (ShortcutAction.mouseWheelZoom.value) {
      zoomTo(x, y, _viewZoomTarget - dy / 30);
    } else {
      _rightMouseMoveAccum += sqrt(dx * dx + dy * dy);
      _viewTranslationTarget[0] -= dx;
      _viewTranslationTarget[1] -= dy;
      markNeedsAdvance();
    }
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
    localMouse = Offset(localX, localY);
    _worldMouse = Vec2D.transformMat2D(
        Vec2D(), Vec2D.fromValues(localX, localY), _inverseViewTransform);
  }

  bool get showSelection => !_isHidingCursor;
  bool get isSelectionEnabled => !_isHidingCursor;

  void _updateHover() {
    if (isSelectionEnabled) {
      AABB cursorAABB = AABB.fromValues(_worldMouse[0], _worldMouse[1],
          _worldMouse[0] + 1, _worldMouse[1] + 1);
      StageItem hover;
      if (_hoverOffsetIndex == -1) {
        visTree.query(cursorAABB, (int proxyId, StageItem item) {
          if (item.isSelectable &&
              (hover == null || item.compareDrawOrderTo(hover) >= 0) &&
              item.hitHiFi(_worldMouse)) {
            hover = item.hoverTarget;
          }
          return true;
        });
      } else {
        List<StageItem> candidates = [];
        visTree.query(cursorAABB, (int proxyId, StageItem item) {
          if (item.isSelectable && item.hitHiFi(_worldMouse)) {
            candidates.add(item);
          }
          return true;
        });
        if (candidates.isNotEmpty) {
          candidates.sort((a, b) => b.compareDrawOrderTo(a));
          hover = candidates[_hoverOffsetIndex % candidates.length];
        }
      }
      hover?.isHovered = true;
      if (hover == null) {
        hoverItem = null;
      }
    }
  }

  void mouseMove(int button, double x, double y) {
    _hoverOffsetIndex = -1;
    _computeWorldMouse(x, y);
    _updatePanIcon();

    file.core.cursorMoved(_worldMouse[0], _worldMouse[1]);

    _updateHover();

    _lastMousePosition[0] = x;
    _lastMousePosition[1] = y;

    if (_activeTool is MoveableTool &&
        (_activeTool as MoveableTool).updateMove(_worldMouse)) {
      // Only advance if the tool specifically requests it.
      markNeedsAdvance();
    }
  }

  void mouseDown(int button, double x, double y) {
    _computeWorldMouse(x, y);
    _lastMousePosition[0] = x;
    _lastMousePosition[1] = y;

    switch (button) {
      case 1:
        if (_panHandCursor != null) {
          _isPanning = true;
        } else if (tool is ClickableTool) {
          final artboard = activeArtboard;
          (tool as ClickableTool)
              .onClick(artboard, tool.mouseWorldSpace(artboard, _worldMouse));
        } else if (isSelectionEnabled) {
          if (_hoverItem != null) {
            _mouseDownSelected = true;
            if (customSelectionHandler != null) {
              if (customSelectionHandler(_hoverItem)) {
                file.select(_hoverItem);
              }
            } else {
              file.select(_hoverItem);
            }
          } else {
            _mouseDownSelected = false;
          }
        } else {
          _mouseDownSelected = false;
        }

        break;
      case 2:
        _isPanning = true;
        _rightClickHandCursor?.remove();
        _rightClickHandCursor = showCustomCursor('cursor-hand');
        break;
      default:
    }
  }

  void mouseDrag(int button, double x, double y) {
    _computeWorldMouse(x, y);
    file.core.cursorMoved(_worldMouse[0], _worldMouse[1]);
    // Store the tool that got activated by this operation separate from the
    // _activeTool so we can know if we were already dragging.
    StageTool activatedTool;
    if (_isPanning) {
      double dx = x - _lastMousePosition[0];
      double dy = y - _lastMousePosition[1];

      _rightMouseMoveAccum += sqrt(dx * dx + dy * dy);
      _viewTranslationTarget[0] += dx;
      _viewTranslationTarget[1] += dy;

      _lastMousePosition[0] = x;
      _lastMousePosition[1] = y;
      markNeedsAdvance();
    } else {
      if (tool is TransformingTool) {
        if (_activeTool == null) {
          activatedTool = tool;
          activatedTool.setEditMode(activeEditMode);
          (activatedTool as TransformingTool).startTransformers(
              file.selection.items.whereType<StageItem>(), _worldMouse);
        } else {
          (_activeTool as TransformingTool).advanceTransformers(_worldMouse);
        }
      }
      if (tool is DraggableTool) {
        var artboard = activeArtboard;
        var worldMouse = tool.mouseWorldSpace(artboard, _worldMouse);

        // [_activeTool] is [null] before dragging operation starts.
        if (_activeTool == null) {
          activatedTool = tool;
          activatedTool.setEditMode(activeEditMode);
          (activatedTool as DraggableTool).startDrag(
              file.selection.items.whereType<StageItem>(),
              artboard,
              worldMouse);
        } else {
          // [_activeTool] dragging operation has already started, so we
          // need to progress.
          (_activeTool as DraggableTool).drag(worldMouse);
        }
      }
    }

    if (activatedTool != null) {
      _activeTool = activatedTool;
    }
  }

  void mouseUp(int button, double x, double y) {
    _isPanning = false;
    _rightClickHandCursor?.remove();
    _rightClickHandCursor = null;
    _computeWorldMouse(x, y);

    _lastMousePosition[0] = x;
    _lastMousePosition[1] = y;
    if (button == 2 && _rightMouseMoveAccum < 5) {
      // show a popup.
    }

    bool toolCompleted = false;

    // See if either a drag or transform operation was in progress.
    if (_activeTool is TransformingTool) {
      (_activeTool as TransformingTool).completeTransformers();
      toolCompleted = true;
    }
    if (_activeTool is DraggableTool) {
      (_activeTool as DraggableTool).endDrag();
      toolCompleted = true;
    }

    if (toolCompleted) {
      _activeTool = null;
      file.core.captureJournalEntry();
      markNeedsAdvance();
    } else if (!_mouseDownSelected) {
      file.selection.clear();
    }
  }

  void mouseExit(int button, double x, double y) {
    _computeWorldMouse(x, y);
    _worldMouse = null;
    hoverItem = null;
    if (_activeTool is MoveableTool) {
      (_activeTool as MoveableTool).onExit();
    }
    _updatePanIcon();
  }

  Artboard get activeArtboard => file.core?.backboard?.activeArtboard;

  final AABBTree<StageItem> visTree = AABBTree<StageItem>(padding: 0);

  StreamSubscription<bool> _isActiveSubscription;

  Stage(this.file) {
    for (final object in file.core.objects) {
      if (object is Component) {
        initComponent(object);
      }
    }
    _isActiveSubscription = file.isActiveStream.listen(_fileActiveChanged);

    file.addActionHandler(_handleAction);
  }

  bool _handleAction(ShortcutAction action) {
    switch (action) {
      case ShortcutAction.cycleHover:
        _hoverOffsetIndex = max(1, _hoverOffsetIndex + 1);
        _updateHover();
        return true;
      default:
        return false;
    }
  }

  /// Deal with the fileContext being activate/de-activated. This happens when a
  /// tab containing the file is selected/changed. An inactive stage should be
  /// kept in memory for quick retrieval if the user goes back to the tab, but
  /// we don't want it listening to shortcuts anymore. Anything processing that
  /// can be temporarily suspended should be. It can be re-activated when
  /// isActive changes to true again. Eventually the stage object will have
  /// [dispose] called when the tab has been deselected for enough time.
  void _fileActiveChanged(bool isActive) {
    if (isActive) {
      ShortcutAction.pan.addListener(_panActionChanged);
    } else {
      ShortcutAction.pan.removeListener(_panActionChanged);
    }
  }

  void _panActionChanged() {
    if (!ShortcutAction.pan.value) {
      // No longer panning? Break us out of a drag operation if we were in one.
      _isPanning = false;
    }
    _updatePanIcon();
  }

  void _updatePanIcon() {
    if (_isPanning) {
      return;
    }
    // _worldMouse is null when we're hovered out of the stage
    if (_worldMouse != null && ShortcutAction.pan.value) {
      _panHandCursor ??= showCustomCursor('cursor-hand');
    } else {
      _panHandCursor?.remove();
      _panHandCursor = null;
    }
  }

  void markNeedsAdvance() {
    if (!_needsAdvance) {
      _needsAdvance = true;
      file.markNeedsAdvance();
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

        // Only automatically add items that are marked automatic.
        if (stageItem.isAutomatic) {
          addItem(stageItem);
        }
      }
    }
  }

  void updateBounds(StageItem item) {
    visTree.placeProxy(item._visTreeProxy, item.aabb);
    markNeedsAdvance();
  }

  bool addItem(StageItem item) {
    assert(item != null);
    if (item._visTreeProxy != nullNode) {
      return false;
    }

    item._visTreeProxy = visTree.createProxy(item.aabb, item);
    item.addedToStage(this);
    markNeedsAdvance();
    if (item is Advancer) {
      _advancingItems.add(item as Advancer);
    }
    return true;
  }

  bool removeItem(StageItem item) {
    assert(item != null);
    if (item._visTreeProxy == nullNode) {
      return false;
    }

    visTree.destroyProxy(item._visTreeProxy);
    item._visTreeProxy = nullNode;
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

  void dispose() {
    file.removeActionHandler(_handleAction);
    _isActiveSubscription.cancel();
    _fileActiveChanged(false);
    _panHandCursor?.remove();
    _rightClickHandCursor?.remove();
  }

  bool get shouldAdvance => _needsAdvance || needsDebounce;
  bool _needsAdvance = true;

  void advance(double elapsed) {
    debounceAll();
    markNeedsRedraw();

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

  void draw(PaintingContext context, Offset offset, Size size) {
    // file.core.startDrawStage();
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

    // Clear bg.
    var backboardColor = file.core.backboard.color;
    canvas.drawRect(
        offset & size,
        Paint()
          ..isAntiAlias = false
          ..color = backboardColor);

    // Compute backboard contrast to help us calculate a color that'll look
    // contrasty on top of it.
    var contrast = ((backboardColor.red * 299 +
                backboardColor.green * 587 +
                backboardColor.blue * 114) /
            1000)
        .round();

    // Help the contrast not be too stark.
    StageItem.backboardContrastPaint.color = contrast > 128
        // If the value is bright, darken as brightness goes up.
        ? Colors.black.withOpacity((1 - (contrast - 128) / 128) * 0.3 + 0.6)
        // If the value is dark, darken as darkness decreases.
        : Colors.white.withOpacity(contrast / 128 * 0.3 + 0.5);

    canvas.save();
    // Translate to widget space
    canvas.clipRect(offset & size);
    canvas.translate(offset.dx, offset.dy);
    canvas.save();

    // Transform to world space
    canvas.transform(viewTransform.mat4);

    _visibleItems.sort((StageItem a, StageItem b) => a.drawOrder - b.drawOrder);

    for (final StageItem item in _visibleItems) {
      item.draw(canvas);
    }

    canvas.restore();

    // Widget space
    _activeTool?.draw(canvas);
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
    LinearGradientBase.typeKey: () => StageLinearGradient(),
    RadialGradientBase.typeKey: () => StageRadialGradient(),
    GradientStopBase.typeKey: () => StageGradientStop(),
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
    // TODO: Try to get the StagePaths or the StageShapes from the current
    // selection, and set it the current editing shape.
  }

  void hideCursor() {
    _isHidingCursor = true;
    markNeedsRedraw();
    delegate?.customCursor?.hide();
  }

  void showCursor() {
    _isHidingCursor = false;
    markNeedsRedraw();
    delegate?.customCursor?.show();
  }

  CursorInstance showCustomCursor(String icon) {
    if (delegate?.customCursor != null) {
      return CursorIcon.build(delegate.customCursor, icon);
    }
    return null;
  }

  /// Trigger an action through the stage. Used to change tool selection after
  /// an action is completed
  void activateAction(ShortcutAction action) => file.rive.triggerAction(action);
}
