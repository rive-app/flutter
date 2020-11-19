import 'dart:collection';
import 'dart:math';

import 'package:cursor/propagating_listener.dart';
import 'package:flutter/widgets.dart';
import 'package:rive_core/animation/cubic_interpolator.dart';
import 'package:rive_core/animation/keyframe.dart';
import 'package:rive_core/animation/keyframe_interpolation.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_editor/rive/managers/animation/animation_time_manager.dart';
import 'package:rive_editor/rive/managers/animation/keyframe_manager.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/widgets/common/value_stream_builder.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/popup/context_popup.dart';
import 'package:rive_editor/widgets/popup/list_popup.dart';
import 'package:rive_editor/widgets/theme.dart';
import 'package:utilities/list_equality.dart';

const double _padding = 20;
const double _renderPadding = _padding + 0.5;

/// Draws the interpolation preview and allows interacting/changing parameters
/// (such as cubic).
class InterpolationPreview extends StatelessWidget {
  final InterpolationViewModel interpolation;
  final HashSet<KeyFrame> selection;
  final KeyFrameManager manager;
  final AnimationTimeManager timeManager;

  const InterpolationPreview({
    @required this.interpolation,
    @required this.selection,
    @required this.manager,
    @required this.timeManager,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueStreamBuilder<double>(
      stream: timeManager.currentTime,
      // ignore: missing_return
      builder: (context, snapshot) {
        var frame = snapshot.data;
        double normalizedTime = equalValue<KeyFrame, double>(selection, (key) {
              var keyedProperty = key.keyedProperty;
              var next = keyedProperty?.after(key);
              return next == null
                  ? -1
                  : (frame - key.frame) / (next.frame - key.frame);
            }) ??
            -1;
        switch (interpolation.type) {
          case KeyFrameInterpolation.hold:
            return _HoldPreviewRenderer(
              theme: RiveTheme.of(context),
              normalizedTime: normalizedTime,
            );
          case KeyFrameInterpolation.linear:
            return _LinearPreviewRenderer(
              theme: RiveTheme.of(context),
              normalizedTime: normalizedTime,
            );
          case KeyFrameInterpolation.cubic:
            var commonInterpolator = interpolation.interpolator;

            if (commonInterpolator is CubicInterpolator) {
              return _CubicManipulator(
                interpolator: commonInterpolator,
                keyFrameManager: manager,
                child: _CubicPreviewRenderer(
                  theme: RiveTheme.of(context),
                  normalizedTime: normalizedTime,
                  controlIn:
                      Offset(commonInterpolator.x1, commonInterpolator.y1),
                  controlOut:
                      Offset(commonInterpolator.x2, commonInterpolator.y2),
                ),
              );
            }
            // I HATE THIS!
            // https://media.giphy.com/media/lWnWVVvNLL9hC/giphy.gif
            continue empty;
          empty:
          default:
            return _EmptyPreviewRenderer(
              theme: RiveTheme.of(context),
              normalizedTime: normalizedTime,
            );
        }
      },
    );
  }
}

class _CubicManipulator extends StatefulWidget {
  final Widget child;
  final CubicInterpolator interpolator;
  final KeyFrameManager keyFrameManager;

  const _CubicManipulator({
    Key key,
    this.child,
    this.interpolator,
    this.keyFrameManager,
  }) : super(key: key);
  @override
  __CubicManipulatorState createState() => __CubicManipulatorState();
}

/// Calculates the quadrant in which the world mouse is with reference to the
/// previous vertex
Offset _calculateLockAxis(Offset position, Offset origin) {
  // 45 degree increments
  const lockInc = pi / 4;

  // Calculate the angle
  final posVec = Vec2D.fromValues(position.dx, position.dy);
  final originVec = Vec2D.fromValues(origin.dx, origin.dy);
  final diff = Vec2D.subtract(Vec2D(), posVec, originVec);
  final angle = atan2(diff[1], diff[0]);

  // Calculate the closest lock angle
  final lockAngle = (angle / lockInc).round() * lockInc;

  // Calculate the new position
  final deltaX = position.dx - origin.dx;
  final deltaY = position.dy - origin.dy;
  final dist = sqrt(pow(deltaX, 2) + pow(deltaY, 2));

  return Offset(
    origin.dx + dist * cos(lockAngle),
    origin.dy + dist * sin(lockAngle),
  );
}

class __CubicManipulatorState extends State<_CubicManipulator> {
  // Locks rotation to 45 degree increments
  final StatefulShortcutAction<bool> lockRotationShortcut =
      ShortcutAction.symmetricDraw;

  // Tracks if an active darg is happening on either the in or out handle
  bool _draggingIn;

  // Does the widget need to refresh due to a rotation lock event?
  bool _rotationLockedRefresh = false;

  // Tracks the last propagating event so that when the lock rotation key is
  // pressed/released, then this event can be used to reposition the handle
  // without waiting for a mouse event
  PropagatingEvent<PointerMoveEvent> _lastMoveEvent;

  @override
  void initState() {
    super.initState();
    // Listen for lock rotation shortcut keypresses
    lockRotationShortcut.addListener(_lockRotationListener);
  }

  @override
  void dispose() {
    lockRotationShortcut.removeListener(_lockRotationListener);
    super.dispose();
  }

  void _lockRotationListener() => setState(() => _rotationLockedRefresh = true);

  void _handleCursor(
      Offset local, void Function(bool isIn, Offset controlPoint) callback) {
    var interpolator = widget.interpolator;
    var size = context.size;
    var heightRange = size.height - 2 * _renderPadding;

    // Calculate the in and out offsets from the widget padding
    var offsetIn = Offset(interpolator.x1 * size.width,
        _renderPadding + heightRange - interpolator.y1 * heightRange);
    var offsetOut = Offset(interpolator.x2 * size.width,
        _renderPadding + heightRange - interpolator.y2 * heightRange);

    // Calculate the origins of the in and out handles
    var inOrigin = Offset(0, size.height - _renderPadding);
    var outOrigin = Offset(size.width, _renderPadding);

    // Calculate the distance squared from local to in and out handles
    var dIn = (local - offsetIn).distanceSquared;
    var dOut = (local - offsetOut).distanceSquared;

    // If the rotation lock is active, lock the axis of the active or closest
    // handle
    var modifiedLocal = local;
    var draggingIn = _draggingIn ?? (dIn < dOut);
    if (lockRotationShortcut.value) {
      modifiedLocal = draggingIn
          ? _calculateLockAxis(local, inOrigin)
          : _calculateLockAxis(local, outOrigin);
    }

    callback(
      draggingIn,
      Offset(modifiedLocal.dx / size.width,
          (modifiedLocal.dy - _renderPadding - heightRange) / -heightRange),
    );
  }

  @override
  Widget build(BuildContext context) {
    var interpolator = widget.interpolator;

    // If the rotation lock is activated/deactivated, then refresh the handle
    // position immediately
    if (_rotationLockedRefresh && _lastMoveEvent != null) {
      _rotationLockedRefresh = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleCursor(_lastMoveEvent.pointerEvent.localPosition, (_, control) {
          CubicInterpolationViewModel cubic;
          if (_draggingIn) {
            cubic = CubicInterpolationViewModel(
                control.dx, control.dy, interpolator.x2, interpolator.y2);
          } else {
            cubic = CubicInterpolationViewModel(
                interpolator.x1, interpolator.y1, control.dx, control.dy);
          }
          widget.keyFrameManager.changeCubic.add(cubic);
        });
      });
    }

    return PropagatingListener(
      onPointerDown: (details) {
        if (details.pointerEvent.buttons == 2) {
          double width = RiveTheme.find(context).dimensions.contextMenuWidth;
          ListPopup<PopupContextItem>.show(
            context,
            showArrow: false,
            position: details.pointerEvent.position + const Offset(0, -6),
            width: width,
            itemBuilder: (popupContext, item, isHovered) =>
                item.itemBuilder(popupContext, isHovered),
            items: [
              PopupContextItem(
                'Reset',
                select: () {
                  widget.keyFrameManager.changeCubic
                      .add(const CubicInterpolationViewModel(0.42, 0, 0.58, 1));
                },
              ),
            ],
          );
          return;
        }

        _handleCursor(details.pointerEvent.localPosition, (isIn, control) {
          CubicInterpolationViewModel cubic;
          if (_draggingIn = isIn) {
            cubic = CubicInterpolationViewModel(
                control.dx, control.dy, interpolator.x2, interpolator.y2);
          } else {
            cubic = CubicInterpolationViewModel(
                interpolator.x1, interpolator.y1, control.dx, control.dy);
          }
          widget.keyFrameManager.changeCubic.add(cubic);
        });
      },
      onPointerMove: (details) {
        _handleCursor(details.pointerEvent.localPosition, (_, control) {
          CubicInterpolationViewModel cubic;

          // Record the last move event in case it's needed for a rotation lock
          _lastMoveEvent = details;

          if (_draggingIn) {
            cubic = CubicInterpolationViewModel(
                control.dx, control.dy, interpolator.x2, interpolator.y2);
          } else {
            cubic = CubicInterpolationViewModel(
                interpolator.x1, interpolator.y1, control.dx, control.dy);
          }
          widget.keyFrameManager.changeCubic.add(cubic);
        });
      },
      onPointerUp: (details) {
        _draggingIn = null;
        _lastMoveEvent = null;
        interpolator.context.captureJournalEntry();
      },
      child: widget.child,
    );
  }
}

class _HoldPreviewRenderer extends LeafRenderObjectWidget {
  final RiveThemeData theme;
  final double normalizedTime;

  const _HoldPreviewRenderer({
    @required this.theme,
    @required this.normalizedTime,
  });
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _HoldPreviewRenderBox()
        ..theme = theme
        ..normalizedTime = normalizedTime;

  @override
  void updateRenderObject(
      BuildContext context, _HoldPreviewRenderBox renderObject) {
    renderObject
      ..theme = theme
      ..normalizedTime = normalizedTime;
  }
}

abstract class _InterpolationRenderBox extends RenderBox {
  double _normalizedTime = 0;
  double get normalizedTime => _normalizedTime;
  set normalizedTime(double value) {
    if (_normalizedTime == value) {
      return;
    }
    _normalizedTime = value;
    markNeedsPaint();
    return;
  }

  final Paint timePaint = Paint()
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke;

  final Paint interpolationPaint = Paint()
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke;

  final Paint separatorPaint = Paint()
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke;
  final Paint background = Paint();

  RiveThemeData _theme;
  RiveThemeData get theme => _theme;
  set theme(RiveThemeData value) {
    if (_theme == value) {
      return;
    }
    _theme = value;
    interpolationPaint.shader = LinearGradient(colors: [
      value.colors.interpolationControlHandleIn,
      value.colors.interpolationControlHandleOut
    ]).createShader(const Rect.fromLTWH(0, 0, 160, 160));
    separatorPaint.color = value.colors.interpolationPreviewSeparator;
    background.color = value.colors.interpolationCurveBackground;
    timePaint.color = value.colors.key;
    onThemeChanged();
    markNeedsPaint();
  }

  void onThemeChanged() {}

  @override
  void paint(PaintingContext context, Offset offset) {
    var canvas = context.canvas;

    canvas.save();
    canvas.clipRect(offset & size);
    canvas.translate(offset.dx, offset.dy);

    canvas.drawRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(5)),
        background);
    canvas.drawLine(const Offset(0, _renderPadding),
        Offset(size.width, _renderPadding), separatorPaint);
    canvas.drawLine(Offset(0, size.height - _renderPadding),
        Offset(size.width, size.height - _renderPadding), separatorPaint);

    paintInterpolation(canvas);

    if (_normalizedTime >= 0 && _normalizedTime <= 1) {
      var x = (_normalizedTime * size.width).round() + 0.5;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), timePaint);
    }

    canvas.restore();
  }

  void paintInterpolation(Canvas canvas);
}

class _HoldPreviewRenderBox extends _InterpolationRenderBox {
  @override
  bool get sizedByParent => true;

  @override
  void paintInterpolation(Canvas canvas) {
    canvas.drawLine(Offset(0, size.height - _renderPadding),
        Offset(size.width, size.height - _renderPadding), interpolationPaint);
    canvas.drawLine(
        Offset(size.width - 0.5, size.height - _renderPadding - 0.5),
        Offset(size.width - 0.5, _renderPadding),
        interpolationPaint);
  }
}

class _LinearPreviewRenderer extends LeafRenderObjectWidget {
  final RiveThemeData theme;
  final double normalizedTime;

  const _LinearPreviewRenderer({
    @required this.theme,
    @required this.normalizedTime,
  });
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _LinearPreviewRenderBox()
        ..theme = theme
        ..normalizedTime = normalizedTime;

  @override
  void updateRenderObject(
      BuildContext context, _LinearPreviewRenderBox renderObject) {
    renderObject
      ..theme = theme
      ..normalizedTime = normalizedTime;
  }
}

class _LinearPreviewRenderBox extends _InterpolationRenderBox {
  @override
  bool get sizedByParent => true;

  @override
  void paintInterpolation(Canvas canvas) {
    canvas.drawLine(Offset(0, size.height - _renderPadding),
        Offset(size.width, _renderPadding), interpolationPaint);
  }
}

class _CubicPreviewRenderer extends LeafRenderObjectWidget {
  final RiveThemeData theme;
  final double normalizedTime;
  final Offset controlIn;
  final Offset controlOut;

  const _CubicPreviewRenderer({
    @required this.theme,
    @required this.normalizedTime,
    @required this.controlIn,
    @required this.controlOut,
  });
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _CubicPreviewRenderBox()
        ..theme = theme
        ..normalizedTime = normalizedTime
        ..controlIn = controlIn
        ..controlOut = controlOut;

  @override
  void updateRenderObject(
      BuildContext context, _CubicPreviewRenderBox renderObject) {
    renderObject
      ..theme = theme
      ..normalizedTime = normalizedTime
      ..controlIn = controlIn
      ..controlOut = controlOut;
  }
}

class _CubicPreviewRenderBox extends _InterpolationRenderBox {
  Offset _renderIn;
  Offset _renderOut;

  final Paint controlLineIn = Paint()
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke;

  final Paint controlLineOut = Paint()
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke;

  final Paint controlHandleIn = Paint();
  final Paint controlHandleOut = Paint();

  final Path cubic = Path();
  Offset _controlIn;
  Offset get controlIn => _controlIn;
  set controlIn(Offset value) {
    if (value == _controlIn) {
      return;
    }
    _controlIn = value;
    markNeedsLayout();
  }

  Offset _controlOut;
  Offset get controlOut => _controlOut;
  set controlOut(Offset value) {
    if (value == _controlOut) {
      return;
    }
    _controlOut = value;
    markNeedsLayout();
  }

  @override
  void onThemeChanged() {
    controlLineIn.color = theme.colors.interpolationControlHandleIn;
    controlLineOut.color = theme.colors.interpolationControlHandleOut;
    controlHandleIn.color = theme.colors.interpolationControlHandleIn;
    controlHandleOut.color = theme.colors.interpolationControlHandleOut;
  }

  @override
  void performLayout() {
    cubic.reset();
    cubic.moveTo(0, size.height - _renderPadding);

    var heightRange = size.height - 2 * _renderPadding;

    _renderIn = Offset(_controlIn.dx * size.width,
        _renderPadding + heightRange - _controlIn.dy * heightRange);
    _renderOut = Offset(_controlOut.dx * size.width,
        _renderPadding + heightRange - _controlOut.dy * heightRange);
    cubic.cubicTo(
      _renderIn.dx,
      _renderIn.dy,
      _renderOut.dx,
      _renderOut.dy,
      size.width,
      _renderPadding,
    );
  }

  @override
  bool get sizedByParent => true;

  @override
  void paintInterpolation(Canvas canvas) {
    canvas.drawPath(cubic, interpolationPaint);

    canvas.drawLine(
        Offset(0, size.height - _renderPadding), _renderIn, controlLineIn);

    canvas.drawLine(
        Offset(size.width, _renderPadding), _renderOut, controlLineOut);

    canvas.drawCircle(_renderIn, 3.5, controlHandleIn);
    canvas.drawCircle(_renderOut, 3.5, controlHandleOut);
  }
}

class _EmptyPreviewRenderer extends LeafRenderObjectWidget {
  final RiveThemeData theme;
  final double normalizedTime;

  const _EmptyPreviewRenderer({
    @required this.theme,
    @required this.normalizedTime,
  });
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _EmptyPreviewRenderBox()
        ..theme = theme
        ..normalizedTime = normalizedTime;

  @override
  void updateRenderObject(
      BuildContext context, _EmptyPreviewRenderBox renderObject) {
    renderObject
      ..theme = theme
      ..normalizedTime = normalizedTime;
  }
}

class _EmptyPreviewRenderBox extends _InterpolationRenderBox {
  @override
  bool get sizedByParent => true;

  @override
  void paintInterpolation(Canvas canvas) {}
}
