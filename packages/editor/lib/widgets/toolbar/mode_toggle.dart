import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

const double _buttonWidth = 96;
const double _height = 30;
const double _borderRadius = 15;

/// Mode toggle button, uses hardcoded with and labels for simplicity but can
/// take N modes in case we add new ones.
class ModeToggle<T> extends StatelessWidget {
  final List<T> modes;
  final T selected;
  final String Function(T) label;
  final void Function(T) select;

  const ModeToggle({
    @required this.modes,
    @required this.selected,
    @required this.label,
    @required this.select,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var theme = RiveTheme.of(context);
    var selectionIndex = modes.indexOf(selected);
    return AnimatedContainer(
      height: _height,
      decoration: _ModeDecoration(
        left: _buttonWidth * selectionIndex,
        fanciness: selectionIndex == 1 ? 1.0 : 0.0,
        background: theme.colors.modeBackground,
        foreground: theme.colors.modeForeground,
      ),
      duration: const Duration(milliseconds: 300),
      curve: const Cubic(0.8, 0, 0, 1),
      child: Row(
        children: [
          for (final mode in modes)
            _ModeLabel(
              label: label(mode),
              isSelected: mode == selected,
              select: () => select(mode),
            ),
        ],
      ),
    );
  }
}

class _ModeLabel extends StatefulWidget {
  final String label;
  final VoidCallback select;
  final bool isSelected;

  const _ModeLabel({
    Key key,
    this.isSelected,
    this.label,
    this.select,
  }) : super(key: key);

  @override
  __ModeLabelState createState() => __ModeLabelState();
}

class __ModeLabelState extends State<_ModeLabel> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    var theme = RiveTheme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => widget.select(),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: SizedBox(
          width: _buttonWidth,
          child: Center(
            child: Padding(
              // pad bottom by 1 px to align to baseline of other tool text
              padding: const EdgeInsets.only(bottom: 1),
              child: Text(
                widget.label,
                style: widget.isSelected || _isHovered
                    ? theme.textStyles.modeLabelSelected
                    : theme.textStyles.modeLabel,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeDecoration extends Decoration {
  const _ModeDecoration({
    this.left,
    this.fanciness,
    this.background,
    this.foreground,
  });

  final double left;
  final double fanciness;
  final Color background;
  final Color foreground;

  @override
  Path getClipPath(Rect rect, TextDirection textDirection) => null;

  @override
  bool get isComplex => false;

  @override
  _ModeDecoration lerpFrom(Decoration a, double t) {
    if (a is _ModeDecoration) {
      return _ModeDecoration(
        left: ui.lerpDouble(a.left, left, t),
        fanciness: ui.lerpDouble(a.fanciness, fanciness, t),
        background: Color.lerp(a.background, background, t),
        foreground: Color.lerp(a.foreground, foreground, t),
      );
    } else {
      return _ModeDecoration(left: left, fanciness: fanciness);
    }
  }

  @override
  _ModeDecoration lerpTo(Decoration b, double t) {
    if (b is _ModeDecoration) {
      return _ModeDecoration(
        left: ui.lerpDouble(left, b.left, t),
        fanciness: ui.lerpDouble(fanciness, b.fanciness, t),
        background: Color.lerp(background, b.background, t),
        foreground: Color.lerp(foreground, b.foreground, t),
      );
    } else {
      return _ModeDecoration(left: left);
    }
  }

  @override
  bool operator ==(dynamic other) =>
      other is _ModeDecoration && left == other.left;

  @override
  int get hashCode => left.hashCode;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..defaultDiagnosticsTreeStyle = DiagnosticsTreeStyle.whitespace
      ..emptyBodyDescription = '<no decorations specified>';

    properties.add(DoubleProperty('left', left, defaultValue: null));
  }

  @override
  bool hitTest(Size size, Offset position, {TextDirection textDirection}) =>
      true;

  @override
  _ModeDecorationPainter createBoxPainter([VoidCallback onChanged]) {
    assert(onChanged != null);
    return _ModeDecorationPainter(
      this,
      onChanged,
    );
  }
}

class _ModeDecorationPainter extends BoxPainter {
  _ModeDecorationPainter(
    this._decoration,
    VoidCallback onChanged,
  )   : assert(_decoration != null),
        super(onChanged);

  final _ModeDecoration _decoration;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    assert(configuration != null);
    assert(configuration.size != null);
    final Rect rect = offset & configuration.size;
    // final TextDirection textDirection = configuration.textDirection;
    var selectedRect = offset + Offset(_decoration.left, 0) &
        Size(_buttonWidth, configuration.size.height);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect,
          const Radius.circular(_borderRadius),
        ),
        Paint()..color = _decoration.background);

    var fanciness = _decoration.fanciness;
    if (fanciness < 1) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
            selectedRect.inflate(-1),
            const Radius.circular(_borderRadius),
          ),
          Paint()..color = _decoration.foreground);
    }
    if (fanciness > 0) {
      ui.Gradient gradient = ui.Gradient.linear(
          Offset(offset.dx + _decoration.left, offset.dy),
          Offset(
            offset.dx + _decoration.left + _buttonWidth,
            offset.dy + _height,
          ),
          const [
            Color(0xFFFF5678),
            Color(0xFFD041AB),
          ],
          const [
            0.0,
            1.0
          ]);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          selectedRect.inflate(-1),
          const Radius.circular(_borderRadius),
        ),
        Paint()
          ..shader = gradient
          ..color = const Color(0xFFFFFFFF).withOpacity(fanciness),
      );
    }
  }

  @override
  String toString() {
    return 'BoxPainter for $_decoration';
  }
}
