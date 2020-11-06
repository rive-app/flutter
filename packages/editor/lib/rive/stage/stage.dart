import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:core/core.dart';
import 'package:core/debouncer.dart';
import 'package:cursor/cursor_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/bones/bone.dart';
import 'package:rive_core/bones/root_bone.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/event.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/shapes/cubic_mirrored_vertex.dart';
import 'package:rive_core/shapes/cubic_asymmetric_vertex.dart';
import 'package:rive_core/shapes/cubic_detached_vertex.dart';
import 'package:rive_core/shapes/ellipse.dart';
import 'package:rive_core/shapes/paint/gradient_stop.dart';
import 'package:rive_core/shapes/paint/radial_gradient.dart';
import 'package:rive_core/shapes/points_path.dart';
import 'package:rive_core/shapes/rectangle.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:rive_core/shapes/straight_vertex.dart';
import 'package:rive_core/shapes/triangle.dart';
import 'package:rive_editor/constants.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/rive/stage/aabb_tree.dart';
import 'package:rive_editor/rive/stage/advancer.dart';
import 'package:rive_editor/rive/stage/items/stage_artboard.dart';
import 'package:rive_editor/rive/stage/items/stage_bone.dart';
import 'package:rive_editor/rive/stage/items/stage_ellipse.dart';
import 'package:rive_editor/rive/stage/items/stage_expandable.dart';
import 'package:rive_editor/rive/stage/items/stage_gradient_stop.dart';
import 'package:rive_editor/rive/stage/items/stage_linear_gradient.dart';
import 'package:rive_editor/rive/stage/items/stage_node.dart';
import 'package:rive_editor/rive/stage/items/stage_path.dart';
import 'package:rive_editor/rive/stage/items/stage_path_vertex.dart';
import 'package:rive_editor/rive/stage/items/stage_points_path.dart';
import 'package:rive_editor/rive/stage/items/stage_radial_gradient.dart';
import 'package:rive_editor/rive/stage/items/stage_rectangle.dart';
import 'package:rive_editor/rive/stage/items/stage_shape.dart';
import 'package:rive_editor/rive/stage/items/stage_triangle.dart';
import 'package:rive_editor/rive/stage/snapper.dart';
import 'package:rive_editor/rive/stage/stage_context_menu_launcher.dart';
import 'package:rive_editor/rive/stage/stage_drawable.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/auto_tool.dart';
import 'package:rive_editor/rive/stage/tools/draggable_tool.dart';
import 'package:rive_editor/rive/stage/tools/late_draw_stage_tool.dart';
import 'package:rive_editor/rive/stage/tools/stage_tool.dart';
import 'package:rive_core/shapes/paint/linear_gradient.dart';
import 'package:rive_editor/rive/stage/tools/transforming_tool.dart';
import 'package:rive_editor/selectable_item.dart';
import 'package:rive_editor/widgets/common/cursor_icon.dart';
import 'package:utilities/restorer.dart';
import 'package:rive_editor/rive/selection_context.dart';
import 'package:utilities/utilities.dart';

enum AxisCheckState { local, parent, world }

/// Direction in which to nudge items
enum NudgeDirection { up, down, left, right }

typedef _ItemFactory = StageItem Function();

abstract class StageDelegate {
  void stageNeedsAdvance();
  void stageNeedsRedraw();
  Future<ui.Image> rasterize();
  BuildContext context;
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
  static const double minZoom = 0.05;
  static const double maxZoom = 16;

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
  final List<StageDrawPass> _drawPasses = [];
  final Vec2D _viewTranslation = Vec2D();
  double _viewZoom = 1;
  double get viewZoom => _viewZoom;
  final Vec2D _viewTranslationTarget = Vec2D();
  double _viewZoomTarget = 1;
  Vec2D _worldMouse = Vec2D();
  Vec2D get worldMouse => _worldMouse;
  Offset localMouse = Offset.zero;
  StageItem _mouseDownHit;
  bool _mouseDownSelectAppend = false;

  // We track the mouse down button as on release we don't get the id of the
  // button released but the state of the set of buttons, so we need to track it
  // ourselves on press.
  int _mouseDownButton = 0;

  /// Returns true if the last click operation resulted in a selection.
  StageItem get mouseDownHit => _mouseDownHit;

  bool _isHidingCursor = false;
  int _hoverOffsetIndex = -1;

  /// We store these two separtely to avoid contention with how they are
  /// activated/disabled.
  CursorInstance _rightClickHandCursor;
  CursorInstance _panHandCursor;

  bool _isPanning = false;
  bool get isPanning => _isPanning;

  /// Flag to track when a drag operation causes an error. When this happens,
  /// all drag events are ignored until the drag operation is ended (e.g. on
  /// mouse up)
  bool _dragInError = false;

  /// The snapping context for the current drag operation.
  Snapper _snapper;
  Snapper get snapper => _snapper ??= Snapper(
        this,
        _worldMouse,
        axisLockNotifier: ShortcutAction.symmetricDraw,
      );

  /// Register a selection handler that will be called back when an item of type
  /// T is selected.
  Restorer addSelectionHandler<T extends SelectableItem>(
      SelectionHandler<T> handler) {
    return file.selection.addHandler((item) {
      if (item is T) {
        return handler(item);
      }
      return false;
    });
  }

  LateDrawViewDelegate lateDrawDelegate;

  StageDelegate _delegate;
  final DetailedEvent<StageContextMenuDetails> _showContextMenu =
      DetailedEvent<StageContextMenuDetails>();
  DetailListenable<StageContextMenuDetails> get showContextMenu =>
      _showContextMenu;

  final ValueNotifier<StageTool> _toolNotifier = ValueNotifier<StageTool>(null);
  ValueListenable<StageTool> get toolListenable => _toolNotifier;

  StageTool _dragTool;
  // The tool we called ".click" on.
  StageTool _clickTool;
  StageTool get tool => _toolNotifier.value;
  set tool(StageTool value) {
    if (_toolNotifier.value == value) {
      return;
    }
    if (value.activate(this)) {
      _toolNotifier.value?.deactivate();
      _toolNotifier.value = value;
      _completeDrag();
      if (value.activateSendsMouseMove) {
        _sendMouseMoveToTool();
      }
    }

    // Update the late draw render object to know which tool it should be
    // delegating draw operations for (if any).
    if (value is LateDrawStageTool) {
      lateDrawDelegate?.tool = value as LateDrawStageTool;
    } else {
      lateDrawDelegate?.tool = null;
    }
  }

  void _sendMouseMoveToTool() {
    if (_worldMouse == null) {
      // Worldmouse can get set to null when we mouse out of the stage.
      return;
    }
    var artboard = activeArtboard;
    if (artboard != null &&
        tool.mouseMove(artboard, tool.mouseWorldSpace(artboard, _worldMouse))) {
      markNeedsAdvance();
    }
  }

  /// We call this internally when the stage state changes in a way that could
  /// cause the active tool to no longer be valid.
  bool _validateTool() {
    if (tool != null && !tool.validate(this)) {
      // Deactivate any operation that was in progress if this tool is no longer
      // valid.
      _completeDrag();
      // The auto tool is always valid.
      tool = AutoTool.instance;
      return false;
    }
    return true;
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

  // Enable snapping flag
  final ValueNotifier<bool> enableSnappingNotifier = ValueNotifier<bool>(true);
  bool get enableSnapping => enableSnappingNotifier.value;
  set enableSnapping(bool value) {
    if (enableSnappingNotifier.value != value) {
      enableSnappingNotifier.value = value;
    }
  }

  // Track the previous value of the snapping flag, so that the snapping
  // shortcut can return to the prior snappig state when it is enabled/disabled
  var _priorEnableSnapping = true;
  var _disableSnappingShortcutEnabled = false;

  // Show nodes flag
  final ValueNotifier<bool> showNodesNotifier = ValueNotifier<bool>(true);
  bool get showNodes => showNodesNotifier.value;
  set showNodes(bool value) {
    if (showNodesNotifier.value != value) {
      showNodesNotifier.value = value;
      // Redraw the stage to show or hide the nodes
      markNeedsRedraw();
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
    var isFirst = _viewportWidth == 0 && _viewportHeight == 0;
    if (width == _viewportWidth && height == _viewportHeight) {
      return false;
    }
    _viewportWidth = width;
    _viewportHeight = height;
    markNeedsAdvance();

    if (isFirst) {
      zoomFit(animate: false, padding: 0, maxZoom: 1);
    }
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

  void mouseWheel(double dx, double dy, bool forceZoom) {
    if (ShortcutAction.mouseWheelZoom.value || forceZoom) {
      zoomTo(_lastMousePosition[0], _lastMousePosition[1],
          _viewZoomTarget - dy / 100);
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
  bool get isSelectionEnabled => !_isHidingCursor && _selectionSuppression == 0;

  int _selectionSuppression = 0;
  Restorer suppressSelection() {
    _selectionSuppression++;
    return RestoreCallback(_restoreSelection);
  }

  bool _restoreSelection() {
    _selectionSuppression--;
    assert(_selectionSuppression >= 0);
    return _selectionSuppression == 0;
  }

  final ValueNotifier<bool> _isHidingHandlesNotifier =
      ValueNotifier<bool>(false);
  ValueListenable<bool> get isHidingHandlesChanged => _isHidingHandlesNotifier;
  bool get isHidingHandles => _isHidingHandlesNotifier.value;

  int _handleSuppression = 0;

  /// General setting for hiding/showing handles on the stage. Can be used  by
  /// things like the transform tools and the color inspector to hide the
  /// transform handles when the color inspector is opened.
  Restorer hideHandles() {
    _handleSuppression++;
    _isHidingHandlesNotifier.value = true;
    return RestoreCallback(_restoreHandles);
  }

  bool _restoreHandles() {
    _handleSuppression--;
    assert(_handleSuppression >= 0);
    if (_handleSuppression == 0) {
      _isHidingHandlesNotifier.value = false;
    }
    return _handleSuppression == 0;
  }

  bool isItemSelectable(StageItem item) =>
      item.isHoverSelectable &&
      tool.canSelect(item) &&
      (soloItems == null || isValidSoloSelection(item));

  /// [callback] is called with each StageItem that is currently under the
  /// cursor. No filtering is done for hover/select validation.
  void forEachHover(bool Function(StageItem) callback) {
    AABB cursorAABB = AABB.fromValues(
        _worldMouse[0], _worldMouse[1], _worldMouse[0] + 1, _worldMouse[1] + 1);
    visTree.query(cursorAABB, (int proxyId, StageItem item) {
      return callback(item);
    });
  }

  void _updateHover({bool Function(StageItem) filter}) {
    if (isSelectionEnabled && _worldMouse != null) {
      StageItem hover;
      if (_hoverOffsetIndex == -1) {
        forEachHover((item) {
          if ((filter?.call(item) ?? true) &&
              isItemSelectable(item) &&
              (hover == null || item.compareDrawOrderTo(hover) >= 0) &&
              item.hitHiFi(_worldMouse)) {
            hover = item;
          }
          return true;
        });
      } else {
        List<StageItem> candidates = [];
        forEachHover((item) {
          if ((filter?.call(item) ?? true) &&
              isItemSelectable(item) &&
              item.hitHiFi(_worldMouse)) {
            candidates.add(item);
          }
          return true;
        });
        if (candidates.isNotEmpty) {
          candidates.sort((a, b) => b.compareDrawOrderTo(a));
          hover = candidates[_hoverOffsetIndex % candidates.length];
        }
      }
      hover?.selectionTarget?.isHovered = true;
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

    _sendMouseMoveToTool();
  }

  final List<StageExpandable> _allExpanded = [];
  StageItem _lastMouseUpHit;
  DateTime _lastUpTime = DateTime.now();

  void clearExpandedNodes() {
    for (final node in _allExpanded) {
      node.isExpanded = false;
    }
    _allExpanded.clear();
  }

  void mouseDown(int button, double x, double y) {
    // Assume nothing was hit, we'll compute if something was below...
    _mouseDownHit = null;

    _computeWorldMouse(x, y);
    _lastMousePosition[0] = x;
    _lastMousePosition[1] = y;

    _mouseDownButton = button;
    switch (button) {
      case 1:
        // If the user clicks while an updatePanIcon is scheduled, accelerate it
        // so we get the pan action.
        debounceAccelerate(_updatePanIcon);
        if (_panHandCursor != null) {
          _isPanning = true;
        } else if (isSelectionEnabled && _hoverItem != null) {
          _mouseDownHit = _hoverItem;

          _mouseDownSelectAppend = ShortcutAction.multiSelect.value;

          if (_hoverItem != null &&
              !file.selection.isCustomHandled(_hoverItem)) {
            if (_hoverItem.isSelected) {
              if (_mouseDownSelectAppend) {
                // If the hover item is already selected and we're holding
                // multi-select, then we need to toggle selection off for the
                // hoveritem.
                file.selection.deselect(_hoverItem);
              }
            } else {
              file.select(_hoverItem,
                  append: _mouseDownSelectAppend, skipHandlers: true);
            }
          }
        }

        if (!_isPanning) {
          // Always pipe clicks when not panning to tools or weird things may
          // happen (see VectorPenTool's click). If for some reason we want to
          // filter clicks based on whether _mouseDownHit or not, then consider
          // altering logic in click of autoTool and adding a separate
          // clickSelection callback on the tools so tools like the PenTool can
          // still track the intention of a click occurred.
          _clickTool = tool;
          if (tool.validateClick()) {
            final artboard = activeArtboard;
            tool.click(
                artboard,
                artboard == null
                    ? _worldMouse
                    : tool.mouseWorldSpace(artboard, _worldMouse));
          }
        }
        break;
      case 2:
        _isPanning = true;
        // Delay showing pan cursor in case right click is quick and should
        // trigger context menu.
        debounce(_showPanningCursor, duration: const Duration(seconds: 1));
        break;
      default:
    }

    _updateComponents();
  }

  void _showPanningCursor() {
    cancelDebounce(_showPanningCursor);
    _rightClickHandCursor?.remove();
    _rightClickHandCursor = showCustomCursor(PackedIcon.cursorHand);
  }

  void mouseDrag(int button, double x, double y) {
    // If a drag error has occurred, ignore the drag
    if (_dragInError) {
      return;
    }
    _computeWorldMouse(x, y);
    file.core.cursorMoved(_worldMouse[0], _worldMouse[1]);
    // Store the tool that got activated by this operation separate from the
    // _dragTool so we can know if we were already dragging.
    StageTool dragTool;
    if (_isPanning) {
      if (_rightClickHandCursor == null) {
        _showPanningCursor();
      }
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
        if (_dragTool == null) {
          dragTool = tool;
          (dragTool as TransformingTool).startTransformers(
              file.selection.items.whereType<StageItem>(), _worldMouse);
          // If a snapping context was created by the transformers, initialize
          // it.
          if (_snapper != null) {
            _snapper.init();
          }
        } else {
          _snapper?.advance(_worldMouse, enableSnapping);
          (_dragTool as TransformingTool).advanceTransformers(_worldMouse);
        }
      }
      if (tool is DraggableTool) {
        if (!(tool as DraggableTool).validateDrag()) {
          _dragInError = true;
          return;
        }
        var artboard = activeArtboard;
        var worldMouse = tool.mouseWorldSpace(artboard, _worldMouse);

        // [_dragTool] is [null] before dragging operation starts.
        if (_dragTool == null) {
          dragTool = tool;
          (dragTool as DraggableTool).startDrag(
              file.selection.items.whereType<StageItem>(),
              artboard,
              worldMouse);
        } else {
          // [_dragTool] dragging operation has already started, so we
          // need to progress.
          (_dragTool as DraggableTool).drag(worldMouse);
        }
      }
    }

    if (dragTool != null) {
      _dragTool = dragTool;
    }
    _updateComponents();
  }

  void _updateComponents() {
    /// We call updateComponents here because on some platforms the mouseDrag
    /// event happens between our frame callback and render of the StageView.
    if (activeArtboard != null && activeArtboard.updateComponents()) {
      // If this resulted in an update, we should make sure to update at least
      // one more time for platforms that didn't interleave the drag between
      // advance & render.
      markNeedsAdvance();
    }
  }

  void mouseUp(int buttons, double x, double y) {
    var wasPanning = _isPanning;
    _dragInError = false;
    cancelDebounce(_showPanningCursor);
    _isPanning = false;
    _rightClickHandCursor?.remove();
    _rightClickHandCursor = null;
    _computeWorldMouse(x, y);

    _lastMousePosition[0] = x;
    _lastMousePosition[1] = y;
    if (_mouseDownButton == 2 && _rightMouseMoveAccum < 5) {
      // show a popup.
      if (_hoverItem is StageContextMenuLauncher) {
        var items = (_hoverItem as StageContextMenuLauncher).contextMenuItems;
        if (items != null && items.isNotEmpty) {
          _showContextMenu.notify(StageContextMenuDetails(items, x, y));
        }
      }
    }

    // If we didn't complete an operation and nothing was selected, clear
    // selections.
    if (!_completeDrag() && !_mouseDownSelectAppend) {
      bool isDoubleClick =
          DateTime.now().difference(_lastUpTime) < doubleClickSpeed;

      if (isDoubleClick &&
          _mouseDownHit != null &&
          _mouseDownHit == _lastMouseUpHit) {
        if (_mouseDownHit is StageExpandable) {
          clearExpandedNodes();
          _allExpanded
              .addAll((_mouseDownHit as StageExpandable).allParentExpandables);
          for (final node in _allExpanded) {
            node.isExpanded = true;
          }

          // Only hit items that have backing components when expanding.
          _updateHover(filter: (item) => item.component != null);

          // The expansion caused something else to be hovered, select it.
          if (_hoverItem != _mouseDownHit) {
            var nonExpanded = StageExpandable.findNonExpanded(_hoverItem);
            if (nonExpanded != null) {
              file.select(nonExpanded);
            }
          }
          markNeedsRedraw();
        } else if (_mouseDownHit is StagePath) {
          file.vertexEditor.activateForSelection(recursivePaths: true);
        }
      } else if (isDoubleClick && tool is AutoTool) {
        file.vertexEditor.deactivate();
      }

      if (_mouseDownHit == null && !wasPanning) {
        file.selection.clear();
      }
    }
    _lastUpTime = DateTime.now();
    _lastMouseUpHit = _mouseDownHit;

    _updateComponents();
  }

  /// Complete any operation the active tool was performing.
  bool _completeDrag() {
    bool toolCompleted = _clickTool?.endClick() ?? false;
    _clickTool = null;

    if (_dragTool != null) {
      // See if either a drag or transform operation was in progress.
      if (_dragTool is TransformingTool) {
        (_dragTool as TransformingTool).completeTransformers();
        toolCompleted = true;
        _snapper?.dispose();
        _snapper = null;
      }
      if (_dragTool is DraggableTool) {
        (_dragTool as DraggableTool).endDrag();
        toolCompleted = true;
      }
    }
    if (toolCompleted) {
      _dragTool = null;
      file.core.captureJournalEntry();
      markNeedsAdvance();
      return true;
    }
    return false;
  }

  bool _wasHidingCursor = false;
  void mouseExit(int button, double x, double y) {
    _computeWorldMouse(x, y);

    _wasHidingCursor = _isHidingCursor;
    if (_wasHidingCursor) {
      showCursor();
    }

    final artboard = activeArtboard;
    tool?.mouseExit(
        artboard,
        artboard == null
            ? _worldMouse
            : tool.mouseWorldSpace(artboard, _worldMouse));
    _updatePanIcon();
    _worldMouse = null;
    hoverItem = null;
  }

  void mouseEnter(int button, double x, double y) {
    _computeWorldMouse(x, y);

    if (_wasHidingCursor) {
      hideCursor();
    }

    final artboard = activeArtboard;
    tool?.mouseEnter(
        artboard,
        artboard == null
            ? _worldMouse
            : tool.mouseWorldSpace(artboard, _worldMouse));
    _updatePanIcon();
  }

  Artboard get activeArtboard => file.core?.backboard?.activeArtboard;

  final AABBTree<StageItem> visTree = AABBTree<StageItem>(padding: 0);

  Stage(this.file) {
    for (final object in file.core.objects) {
      if (object is Component) {
        initComponent(object);
      }
    }
    file.isActiveListenable.addListener(_fileActiveChanged);
    // Ensure stuff that _fileActiveChanged sets up is et up
    _fileActiveChanged();

    file.activeArtboardChanged.addListener(_activeArtboardChanged);

    file.selection.addListener(_fileSelectionChanged);

    file.addActionHandler(_handleAction);
  }

  void _fileSelectionChanged() {
    if (soloItems != null) {
      // Check that all the selected stageItems are valid for this solo. If not,
      // break out of it.
      for (final item in file.selection.items) {
        if (item is StageItem && !isValidSoloSelection(item)) {
          solo(null);
          break;
        }
      }
    }

    // Validate that the selection is in the exansion otherwise clear it.
    HashSet<StageExpandable> parentExpandables = HashSet<StageExpandable>();
    for (final item in file.selection.items) {
      if (item is StageItem<Component> &&
          item.component?.parentExpandable != null &&
          // There's a case where the parentExpandable isn't necessarily backed
          // by an expandable StageItem (Vertices are inside of Paths, Paths do
          // not have Expandable mixed into their StageItem because the Path
          // launched the vertex editor when it is double clicked on)
          item.component.parentExpandable.stageItem is StageExpandable) {
        parentExpandables
            .add(item.component.parentExpandable.stageItem as StageExpandable);
      }
    }
    clearExpandedNodes();
    for (final expandable in parentExpandables) {
      _allExpanded.addAll(expandable.allParentExpandables);
    }
    for (final node in _allExpanded) {
      node.isExpanded = true;
    }
    // TODO: Maybe only update if expanded changed?
    _updateHover();
  }

  bool isValidSoloSelection(StageItem item) {
    var solo = soloItems;
    // If we're soloing, only items that are directly soloed or have a
    // parent that is soloed are allowed to be selected.
    return solo != null &&
        (solo.contains(item) ||
            (item.soloParent != null && solo.contains(item.soloParent)));
  }

  bool _handleAction(ShortcutAction action) {
    switch (action) {
      case ShortcutAction.cancel:
        // TODO: should we cancel drag operations?
        // For now cancel solo (if there was one).
        if (_soloNotifier.value != null) {
          var items = _soloNotifier.value.toList(growable: false);
          solo(null);

          file.selection.selectMultiple(items);
          tool = AutoTool.instance;
          return true;
        }
        return false;

      case ShortcutAction.cycleHover:
        _hoverOffsetIndex = max(1, _hoverOffsetIndex + 1);
        _updateHover();
        return true;
      case ShortcutAction.zoomIn:
        zoomLevel *= 2;
        break;
      case ShortcutAction.zoomOut:
        zoomLevel /= 2;
        break;
      case ShortcutAction.zoom100:
        zoomLevel = 1;
        break;
      case ShortcutAction.zoomFit:
        zoomFit();
        break;
      case ShortcutAction.nudgeUp:
        _nudgeSelectedItems(NudgeDirection.up);
        break;
      case ShortcutAction.nudgeDown:
        _nudgeSelectedItems(NudgeDirection.down);
        break;
      case ShortcutAction.nudgeLeft:
        _nudgeSelectedItems(NudgeDirection.left);
        break;
      case ShortcutAction.nudgeRight:
        _nudgeSelectedItems(NudgeDirection.right);
        break;
      case ShortcutAction.megaNudgeUp:
        _nudgeSelectedItems(NudgeDirection.up, 10);
        break;
      case ShortcutAction.megaNudgeDown:
        _nudgeSelectedItems(NudgeDirection.down, 10);
        break;
      case ShortcutAction.megaNudgeLeft:
        _nudgeSelectedItems(NudgeDirection.left, 10);
        break;
      case ShortcutAction.megaNudgeRight:
        _nudgeSelectedItems(NudgeDirection.right, 10);
        break;
    }
    return false;
  }

  /// Nudge the set of selected items in a given direction
  void _nudgeSelectedItems(NudgeDirection direction, [int step = 1]) {
    final nudgableComponents = tops<Component>(
      file.selection.items
          .whereType<StageItem>()
          .map<Component>((i) => i.component as Component)
          .where((c) => c is Node || c is RootBone),
    );

    for (final component in nudgableComponents) {
      switch (direction) {
        case NudgeDirection.up:
          // nasty if/else to handle casting to either Node or RootBone
          if (component is Node)
            // ignore: curly_braces_in_flow_control_structures
            component.y -= step;
          else if (component is RootBone) component.y -= step;
          break;
        case NudgeDirection.down:
          if (component is Node)
            // ignore: curly_braces_in_flow_control_structures
            component.y += step;
          else if (component is RootBone) component.y += step;
          break;
          break;
        case NudgeDirection.left:
          if (component is Node)
            // ignore: curly_braces_in_flow_control_structures
            component.x -= step;
          else if (component is RootBone) component.x -= step;
          break;
          break;
        case NudgeDirection.right:
          if (component is Node)
            // ignore: curly_braces_in_flow_control_structures
            component.x += step;
          else if (component is RootBone) component.x += step;
          break;
      }
    }
  }

  /// Fit the selection to the viewport bounds. If nothing is selected the
  /// active artboard is used as the are of interest.
  void zoomFit({
    bool animate = true,
    double padding = 20,
    double minZoom = Stage.minZoom,
    double maxZoom = Stage.maxZoom,
  }) {
    AABB bounds;
    var selection = file.selection.items.whereType<StageItem>();
    if (selection.isNotEmpty) {
      bounds = selection.first.aabb;
      for (final item in selection.skip(1)) {
        bounds = AABB.combine(AABB(), bounds, item.aabb);
      }
    } else {
      var artboard = activeArtboard;
      if (artboard == null) {
        return;
      }

      bounds = AABB.clone(artboard.stageItem.aabb);
      // Extra 18 pixels for title
      bounds.values[1] -= 18;
    }

    if (bounds == null) {
      // Show message?
      return;
    }

    const double zoomFitPadding = 20;
    var availableWidth = _viewportWidth - zoomFitPadding * 2;
    var availableHeight = _viewportHeight - zoomFitPadding * 2;
    var widthScale = availableWidth / bounds.width;
    var heightScale = availableHeight / bounds.height;
    double zoom =
        min(widthScale, heightScale).clamp(minZoom, maxZoom).toDouble();

    _viewZoomTarget = zoom;
    zoomLevelNotifier.value = zoom;

    var center = AABB.center(Vec2D(), bounds);

    _viewTranslationTarget[0] =
        zoomFitPadding + availableWidth / 2 - center[0] * zoom;
    _viewTranslationTarget[1] =
        zoomFitPadding + availableHeight / 2 - center[1] * zoom;

    if (!animate) {
      Vec2D.copy(_viewTranslation, _viewTranslationTarget);
      _viewZoom = _viewZoomTarget;
    }
    markNeedsAdvance();
  }

  void _activeArtboardChanged() {
    // whenever the active artboard changes, send a mouse move to the active
    // tool.
    _sendMouseMoveToTool();
  }

  /// Deal with the fileContext being activate/de-activated. This happens when a
  /// tab containing the file is selected/changed. An inactive stage should be
  /// kept in memory for quick retrieval if the user goes back to the tab, but
  /// we don't want it listening to shortcuts anymore. Anything processing that
  /// can be temporarily suspended should be. It can be re-activated when
  /// isActive changes to true again. Eventually the stage object will have
  /// [dispose] called when the tab has been deselected for enough time.
  void _fileActiveChanged() {
    if (file.isActive) {
      tool?.activate(this);
      ShortcutAction.deepClick.addListener(_deepClickChanged);
      ShortcutAction.pan.addListener(_panActionChanged);
      ShortcutAction.disableSnapping.addListener(_disableSnappingChanged);
    } else {
      tool?.deactivate();
      ShortcutAction.pan.removeListener(_panActionChanged);
      ShortcutAction.deepClick.removeListener(_deepClickChanged);
      ShortcutAction.disableSnapping.addListener(_disableSnappingChanged);
    }
  }

  void _disableSnappingChanged() {
    // If the shortcut key is pressed, save snapping state and disable
    if (!_disableSnappingShortcutEnabled) {
      _priorEnableSnapping = enableSnapping;
      enableSnapping = false;
    } else {
      // Set the snapping state to its prior
      enableSnapping = _priorEnableSnapping;
    }
    _disableSnappingShortcutEnabled = !_disableSnappingShortcutEnabled;
  }

  void _deepClickChanged() => _updateHover();

  void _panActionChanged() {
    if (!ShortcutAction.pan.value) {
      // No longer panning? Break us out of a drag operation if we were in one.
      _isPanning = false;
      // Immediately update the icon
      cancelDebounce(_updatePanIcon);
      _updatePanIcon();
    } else {
      // debounce showing the icon to stop the icon from showing up when someone
      // taps the pan key to start an animation
      debounce(
        _updatePanIcon,
        duration: const Duration(milliseconds: 200),
      );
    }
  }

  void _updatePanIcon() {
    if (_isPanning) {
      return;
    }
    // _worldMouse is null when we're hovered out of the stage
    if (_worldMouse != null && ShortcutAction.pan.value) {
      _panHandCursor ??= showCustomCursor(PackedIcon.cursorHand);
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
        if (stageItem.isAutomatic(this)) {
          addItem(stageItem);
        }
      }
    }
  }

  void updateBounds(StageItem item) {
    assert(item._visTreeProxy != null,
        'Attempting to place an item on the stage after it has been removed.');

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

    // Whenever an item is added to the stage, make sure we update the mouse
    // move in case the item was added under the cursor.
    debounce(_updateHover);
    return true;
  }

  bool removeItem(StageItem item) {
    assert(item != null);

    // If this item didn't belong to this stage, don't try to remove it.
    if (item.stage != this) {
      return false;
    }

    // Make sure items are removed from selection when they are removed from the
    // stage.
    if (file.selection.deselect(item, notify: false)) {
      // Debounce selection notification in case this happens during a widget
      // update cycle.
      debounce(file.selection.notifySelection);
    }

    // Make sure to remove any cached references.
    if (_mouseDownHit == item) {
      _mouseDownHit = null;
    }
    if (_hoverItem == item) {
      item.isHovered = false;
      _hoverItem = null;
    }

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

    // Patch up solo if items are removed that were part of it.
    var currentSolo = soloItems;
    if (currentSolo != null && currentSolo.contains(item)) {
      var nextSolo = HashSet<StageItem>.from(currentSolo)..remove(item);
      solo(nextSolo.isEmpty ? null : nextSolo);
    }
    return true;
  }

  /// Clear out all stage items. Normally called when the file is also wiped.
  void wipe() {
    clearDebounce();
    _soloNotifier.value = null;
    _drawPasses.clear();

    // Make sure that all StageItems in this Stage have their tree proxy nodes
    // set to null before we call visTree.clear so that any further operation
    // peformed on the tree with those nodes is discarded.
    visTree.all((proxyId, item) {
      item._visTreeProxy = nullNode;
      return true;
    });

    visTree.clear();
    hoverItem = null;
  }

  void dispose() {
    var tool = _toolNotifier.value;
    _toolNotifier.value = null;
    tool?.deactivate();

    file.selection.removeListener(_fileSelectionChanged);
    file.removeActionHandler(_handleAction);
    file.isActiveListenable.removeListener(_fileActiveChanged);
    file.activeArtboardChanged.removeListener(_activeArtboardChanged);
    ShortcutAction.pan.removeListener(_panActionChanged);
    ShortcutAction.deepClick.removeListener(_deepClickChanged);
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

    bool movedView = false;
    if (ds.abs() > 0.00001) {
      _needsAdvance = true;
      movedView = true;
      ds *= factor;
    }
    if (dx.abs() > 0.01) {
      _needsAdvance = true;
      movedView = true;
      dx *= factor;
    }
    if (dy.abs() > 0.01) {
      _needsAdvance = true;
      movedView = true;
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

    if (movedView) {
      mouseMove(1, _lastMousePosition[0], _lastMousePosition[1]);
    }
  }

  void draw(PaintingContext context, Offset offset, Size size) {
    // file.core.startDrawStage();
    Mat2D.invert(_inverseViewTransform, _viewTransform);
    var viewAABB = obbToAABB(
        AABB.fromValues(0, 0, _viewportWidth, _viewportHeight),
        _inverseViewTransform);
    _drawPasses.clear();
    visTree.query(viewAABB, (int proxyId, StageItem item) {
      if (item.isVisible) {
        item.drawPasses.forEach(_drawPasses.add);
      }
      return true;
    });

    var canvas = context.canvas;

    canvas.save();
    // Translate to widget space
    canvas.clipRRect(
        RRect.fromRectAndRadius(offset & size, const Radius.circular(5)));

    // Clear bg.
    var backboardColor = file.core.backboard.color;
    canvas.drawRect(
        offset & size,
        Paint()
          ..isAntiAlias = false
          ..color = backboardColor);

    if (_viewportWidth == 0 || _viewportHeight == 0) {
      // Keep this here to prevent flashing on load. Make sure we clear to
      // backboard regardless.
      canvas.restore();
      return;
    }

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

    canvas.translate(offset.dx, offset.dy);
    canvas.save();

    // Transform to world space
    canvas.transform(viewTransform.mat4);
    bool inWorldSpace = true;

    _drawPasses.addAll(tool.drawPasses);

    _drawPasses.sort((StageDrawPass a, StageDrawPass b) => a.order - b.order);

    for (final pass in _drawPasses) {
      // Some items may not draw in world space. Change between world and screen
      // as requested by the drawable. We can't batch here as drawables of
      // different space types might be interleaved at different draw orders.
      if (inWorldSpace != pass.inWorldSpace) {
        if (inWorldSpace = pass.inWorldSpace) {
          canvas.save();
          canvas.transform(viewTransform.mat4);
        } else {
          canvas.restore();
        }
      }
      pass.draw(canvas, pass);
    }

    if (inWorldSpace) {
      canvas.restore();
    }
    _snapper?.draw(canvas);
    canvas.restore();
  }

  final Map<int, _ItemFactory> _factories = {
    ArtboardBase.typeKey: () => StageArtboard(),
    NodeBase.typeKey: () => StageNode(),
    ShapeBase.typeKey: () => StageShape(),
    EllipseBase.typeKey: () => StageEllipse(),
    RectangleBase.typeKey: () => StageRectangle(),
    TriangleBase.typeKey: () => StageTriangle(),
    PointsPathBase.typeKey: () => StagePointsPath(),
    StraightVertexBase.typeKey: () => StagePathVertex(),
    CubicMirroredVertexBase.typeKey: () => StagePathVertex(),
    CubicAsymmetricVertexBase.typeKey: () => StagePathVertex(),
    CubicDetachedVertexBase.typeKey: () => StagePathVertex(),
    LinearGradientBase.typeKey: () => StageLinearGradient(),
    RadialGradientBase.typeKey: () => StageRadialGradient(),
    GradientStopBase.typeKey: () => StageGradientStop(),
    BoneBase.typeKey: () => StageBone(),
    RootBoneBase.typeKey: () => StageBone(),
  };

  @override
  void onNeedsDebounce() => markNeedsAdvance();

  Cursor get _customCursor =>
      delegate?.context != null ? CustomCursor.find(delegate?.context) : null;

  void hideCursor() {
    _isHidingCursor = true;
    markNeedsRedraw();

    _customCursor?.hide();
  }

  void showCursor() {
    _isHidingCursor = false;
    markNeedsRedraw();
    _customCursor?.show();
  }

  CursorInstance showCustomCursor(
    Iterable<PackedIcon> icon, {
    Alignment alignment = Alignment.center,
  }) {
    if (_customCursor != null) {
      return CursorIcon.build(_customCursor, icon, alignment);
    }
    return null;
  }

  /// Trigger an action through the stage. Used to change tool selection after
  /// an action is completed
  void activateAction(ShortcutAction action) => file.rive.triggerAction(action);

  /// The stage has the concept of solo items. This is different from a Solo
  /// Component. When the stage is in solo mode, it means that only solo items
  /// (and their children) can be interacted with. This is useful when doing
  /// complex operations on shapes, paths, meshes that require focus on only a
  /// specific set of stage items. It's also useful when you want to ask the
  /// user to select something of a specific type and want to only allow (and
  /// perhaps highlight) valid selections.
  void solo(Iterable<StageItem> value, {bool darken = false}) {
    if (iterableEquals(_soloNotifier.value, value)) {
      return;
    }
    if (_soloNotifier.value != null) {
      var removedItems = value == null
          ? _soloNotifier.value
          : _soloNotifier.value.difference(value.toSet());
      for (final item in removedItems) {
        item.onSoloChanged(false);
      }
    }

    file.selection.clear();
    _soloNotifier.value = value == null ? null : HashSet<StageItem>.from(value);
    _updateHover();
    _validateTool();
    if (value != null) {
      for (final item in value) {
        item.onSoloChanged(true);
      }
    }
    // TODO: add darken functionality (used when connecting bones, valid
    // contraint targets, etc).
  }

  HashSet<StageItem> get soloItems => _soloNotifier.value;

  final ValueNotifier<HashSet<StageItem>> _soloNotifier =
      ValueNotifier<HashSet<StageItem>>(null);
  ValueListenable<HashSet<StageItem>> get soloListenable => _soloNotifier;

  /// Hide an item on the stage
  void hideItem(StageItem item) => removeItem(item);

  /// Unhide an item on the stage
  void unhideItem(StageItem item) => addItem(item);
}
