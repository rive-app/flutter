import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:rive_editor/widgets/theme.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

class TeamSettingsHeader extends StatelessWidget {
  final TextStyles textStyles = RiveThemeData().textStyles;

  @override
  Widget build(BuildContext context) {
    final riveColors = RiveThemeData().colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 50,
          height: 50,
          child: Stack(
            children: [
              const Positioned.fill(
                  child: CustomPaint(
                      painter: _DashedCirclePainter(
                radius: 25,
              ))),
              Center(
                  child: TintedIcon(
                      color: riveColors.fileIconColor, icon: 'image'))
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rive',
              style: textStyles.fileGreyTextLarge,
            ),
            const SizedBox(height: 2),
            Text(
              'Team Plan',
              style: textStyles.hyperLinkSubtext,
            )
          ],
        ),
        const Spacer(),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '2 members',
              style: textStyles.fileGreyTextLarge,
            ),
            const SizedBox(height: 2),
            Text(
              'Add More',
              style: textStyles.hyperLinkSubtext,
            )
          ],
        ),
      ],
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final double radius;

  const _DashedCirclePainter({@required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1
      ..color = RiveThemeData().colors.commonButtonTextColor
      ..style = PaintingStyle.stroke;

    final circlePath = Path()..addOval(Offset.zero & size);

    canvas.drawPath(
        dashPath(circlePath, dashArray: CircularIntervalList([3, 3])), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    if (oldDelegate is _DashedCirclePainter) {
      return oldDelegate.radius != radius;
    }
    return true;
  }
}
