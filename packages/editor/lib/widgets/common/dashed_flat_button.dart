import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:rive_editor/widgets/common/flat_icon_button.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/theme.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

// 3 pixels painted, 3 gap. etc.
final dashArray = CircularIntervalList([3.toDouble(), 3.toDouble()]);

class DashedPainter extends CustomPainter {
  final double radius;

  const DashedPainter({this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    // drawing a rect of size 30, ends up drawing 31 pixels..
    final appliedSize = Size(size.width, size.height - 1);

    Paint paint = Paint()
      ..strokeWidth = 1
      ..color = RiveThemeData().colors.commonButtonTextColor
      // ..strokeCap = strokeCap
      ..style = PaintingStyle.stroke;
    var path = Path();
    path.addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, appliedSize.width, appliedSize.height),
        Radius.circular(radius)));
    path = dashPath(path, dashArray: dashArray);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class DashedFlatButton extends StatelessWidget {
  final String label;
  final String icon;
  final void Function() onTap;
  const DashedFlatButton({this.label, this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final button = FlatIconButton(
      icon: TintedIcon(
        icon: icon,
        color: RiveTheme.of(context).colors.fileIconColor,
      ),
      label: label,
      color: Colors.transparent,
      onTap: onTap,
    );
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: CustomPaint(
            painter: DashedPainter(radius: button.radius),
          ),
        ),
        button
      ],
    );
  }
}
