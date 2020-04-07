import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/theme.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

class SettingsHeader extends StatelessWidget {
  final String name;
  final int teamSize;
  final String avatarPath;
  final VoidCallback changeAvatar;

  const SettingsHeader(
      {@required this.name, this.teamSize, this.avatarPath, this.changeAvatar});

  bool get isTeam => teamSize > 0;

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    final textStyles = theme.textStyles;
    final riveColors = theme.colors;

    List<Widget> children = [];
    if (avatarPath == null) {
      children.addAll([
        const Positioned.fill(
            child: CustomPaint(
                painter: _DashedCirclePainter(
          radius: 25,
        ))),
        Center(
            child: TintedIcon(color: riveColors.fileIconColor, icon: 'image'))
      ]);
    } else {
      children.add(Center(
        child: SizedBox(
          width: 50,
          height: 50,
          child: CircleAvatar(
            backgroundColor: Colors.transparent,
            backgroundImage: NetworkImage(avatarPath),
          ),
        ),
      ));
    }

    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: GestureDetector(
                onTap: changeAvatar,
                child: Stack(children: children),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: textStyles.fileGreyTextLarge,
                ),
                if (isTeam) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Team Plan',
                    style: textStyles.hyperLinkSubtext,
                  )
                ]
              ],
            ),
            const Spacer(),
            if (isTeam)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$teamSize members',
                    style: textStyles.fileGreyTextLarge
                        .copyWith(fontSize: 13, height: 1.3),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Add More',
                    style: textStyles.hyperLinkSubtext,
                  )
                ],
              ),
          ],
        ));
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
