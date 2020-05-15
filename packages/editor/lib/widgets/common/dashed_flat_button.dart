import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:rive_editor/widgets/common/flat_icon_button.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/popup/tip.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

// 3 pixels painted, 3 gap. etc.
final CircularIntervalList<double> dashArray =
    CircularIntervalList([3.toDouble(), 3.toDouble()]);

class DashedPainter extends CustomPainter {
  final double radius;
  final Color dashColor;
  const DashedPainter({@required this.radius, @required this.dashColor});

  @override
  void paint(Canvas canvas, Size size) {
    // drawing a rect of size 30, ends up drawing 31 pixels..
    final appliedSize = Size(size.width, size.height - 1);

    Paint paint = Paint()
      ..strokeWidth = 1
      ..color = dashColor
      ..style = PaintingStyle.stroke;
    var path = Path();
    path.addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(
          0,
          0.5,
          appliedSize.width,
          appliedSize.height,
        ),
        Radius.circular(radius)));
    path = dashPath(path, dashArray);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class DashedFlatButton extends StatelessWidget {
  const DashedFlatButton({
    @required this.label,
    @required this.icon,
    this.textColor,
    this.iconColor,
    this.hoverTextColor,
    this.hoverIconColor,
    this.onTap,
    this.tip,
  });

  final String label;
  final String icon;
  final Color textColor;
  final Color iconColor;
  final Color hoverIconColor;
  final Color hoverTextColor;
  final VoidCallback onTap;
  final Tip tip;

  @override
  Widget build(BuildContext context) {
    final iconColor =
        this.iconColor ?? RiveTheme.of(context).colors.fileIconColor;

    final button = FlatIconButton(
      icon: TintedIcon(
        icon: icon,
        color: iconColor,
      ),
      hoverIcon: TintedIcon(
        icon: icon,
        color: hoverIconColor,
      ),
      label: label,
      color: Colors.transparent,
      textColor: textColor,
      hoverTextColor: hoverTextColor,
      onTap: onTap,
      tip: tip,
    );
    return CustomPaint(
      painter: DashedPainter(radius: button.radius, dashColor: iconColor),
      child: button,
    );
  }
}

/// Creates a new path that is drawn from the segments of `source`.
///
/// Dash intervals are controled by the `dashArray` - see [CircularIntervalList]
/// for examples.
///
/// `dashOffset` specifies an initial starting point for the dashing.
///
/// Passing in a null `source` will result in a null result.  Passing a `source`
/// that is an empty path will return an empty path.
Path dashPath(Path source, CircularIntervalList<double> dashArray,
    {DashOffset dashOffset}) {
  assert(dashArray != null);
  if (source == null) {
    return null;
  }

  dashOffset ??= DashOffset.zero;

  final dest = Path();

  // Need to turn it into list, or the iterator
  // is run, messing it up later
  final metrics = source.computeMetrics().toList();

  // TODO: temp fix here for CanvasKit; if mertics
  // can't be computed, return the original path.
  if (metrics.isEmpty) {
    return source;
  }
  for (final metric in metrics) {
    var distance = dashOffset._calculate(metric.length);
    var draw = true;
    while (distance < metric.length) {
      final len = dashArray.next;
      if (draw) {
        dest.addPath(
          metric.extractPath(distance, distance + len),
          Offset.zero,
        );
      }
      distance += len;
      draw = !draw;
    }
  }
  return dest;
}

enum _DashOffsetType { absolute, percentage }

/// Specifies the starting position of a dash array on a path, either as a
/// percentage or absolute value.
///
/// The internal value will be guaranteed to not be null.
class DashOffset {
  static const DashOffset zero = DashOffset.absolute(0.0);

  /// Create a DashOffset that will be measured as a percentage of the length
  /// of the segment being dashed.
  ///
  /// `percentage` will be clamped between 0.0 and 1.0; null will be converted
  /// to 0.0.
  DashOffset.percentage(double percentage)
      : _rawVal = percentage.clamp(0, 1).toDouble() ?? 0,
        _dashOffsetType = _DashOffsetType.percentage;

  /// Create a DashOffset that will be measured in terms of absolute pixels
  /// along the length of a [Path] segment.
  ///
  /// `start` will be coerced to 0.0 if null.
  const DashOffset.absolute(double start)
      : _rawVal = start ?? 0.0,
        _dashOffsetType = _DashOffsetType.absolute;

  final double _rawVal;
  final _DashOffsetType _dashOffsetType;

  double _calculate(double length) =>
      _dashOffsetType == _DashOffsetType.absolute ? _rawVal : length * _rawVal;
}

/// A circular array of dash offsets and lengths.
///
/// For example, the array `[5, 10]` would result in dashes 5 pixels long
/// followed by blank spaces 10 pixels long.  The array `[5, 10, 5]` would
/// result in a 5 pixel dash, a 10 pixel gap, a 5 pixel dash, a 5 pixel gap,
/// a 10 pixel dash, etc.
///
/// Note that this does not quite conform to an [Iterable<T>], because it does
/// not have a moveNext.
class CircularIntervalList<T> {
  CircularIntervalList(this._vals);

  final List<T> _vals;
  int _idx = 0;

  T get next {
    if (_idx >= _vals.length) {
      _idx = 0;
    }
    return _vals[_idx++];
  }
}
