import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:rive_editor/rive/editor_alert.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

/// A simple alert message that expires after a few seconds.
class SimpleAlert extends EditorAlert {
  final String label;

  SimpleAlert(
    this.label, {
    bool autoDismiss = true,
  }) {
    if (autoDismiss) {
      Timer(const Duration(seconds: 3), dismiss);
    }
  }

  @override
  Widget build(BuildContext context) {
    var theme = RiveTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      width: 756,
      decoration: BoxDecoration(
        color: theme.colors.panelBackgroundDarkGrey,
        borderRadius: const BorderRadius.all(
          Radius.circular(20),
        ),
      ),
      child: Text(label, style: theme.textStyles.popupText),
    );
  }
}

/// A simple alert message that expires after a few seconds.
class LabeledAlert extends EditorAlert {
  final ValueNotifier<String> _label = ValueNotifier<String>(null);
  Timer _timer;
  String get label => _label.value;
  set label(String value) {
    _label.value = value;

    _delayDismiss();
  }

  void _delayDismiss([bool force = false]) {
    if (!force && _timer == null) {
      return;
    }
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 3), dismiss);
  }

  LabeledAlert(
    String label, {
    bool autoDismiss = true,
  }) {
    _label.value = label;
    _delayDismiss(autoDismiss);
  }

  @override
  Widget build(BuildContext context) {
    var theme = RiveTheme.of(context);
    return RoundedBackground(
      background: theme.colors.globalMessageBackground,
      border: theme.colors.globalMessageBorder,
      thickness: 1.0,
      radius: 20,
      child: Padding(
        padding: const EdgeInsets.only(
          left: 12,
          right: 12,
          top: 12,
          bottom: 13,
        ),
        // width: 756,
        child: ValueListenableBuilder(
          valueListenable: _label,
          builder: (context, String text, _) =>
              Text(text, style: theme.textStyles.popupText),
        ),
      ),
    );
  }
}

class RoundedBackground extends SingleChildRenderObjectWidget {
  final Color background;
  final Color border;
  final double thickness;
  final double radius;

  const RoundedBackground({
    this.background,
    this.border,
    this.thickness,
    this.radius,
    Widget child,
    Key key,
  }) : super(key: key, child: child);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RoundedBackgroundRenderer()
      ..background = background
      ..border = border
      ..thickness = thickness
      ..radius = radius;
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant _RoundedBackgroundRenderer renderObject) {
    renderObject
      ..background = background
      ..border = border
      ..thickness = thickness
      ..radius = radius;
  }
}

class _RoundedBackgroundRenderer extends RenderProxyBox {
  final Paint _fill = Paint()..isAntiAlias = false;
  final Paint _stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..isAntiAlias = true;

  Color _background;
  Color _border;

  double _thickness;
  double _radius;

  _RoundedBackgroundRenderer({
    RenderBox child,
  }) : super(child);

  // @override
  // bool get alwaysNeedsCompositing => child != null;

  double get thickness => _thickness;
  set thickness(double value) {
    if (_thickness == value) return;
    _stroke.strokeWidth = value;
    _thickness = value;
    markNeedsPaint();
  }

  double get radius => _radius;
  set radius(double value) {
    if (_radius == value) return;
    _radius = value;
    markNeedsPaint();
  }

  Color get background => _background;
  set background(Color value) {
    if (_background == value) return;
    _fill.color = value;
    _background = value;
    markNeedsPaint();
  }

  Color get border => _border;
  set border(Color value) {
    if (_border == value) return;
    _stroke.color = value;
    _border = value;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      var canvas = context.canvas;

      var rect =
          RRect.fromRectAndRadius(offset & size, Radius.circular(radius));
      canvas.drawRRect(rect, _fill);
      canvas.drawRRect(rect, _stroke);
      context.paintChild(child, offset);
    }
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (child != null) visitor(child);
  }
}
