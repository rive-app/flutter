import 'package:flutter/material.dart';

import 'package:rive_editor/widgets/inherited_widgets.dart';

class FlatIconButton extends StatelessWidget {
  const FlatIconButton(
      {Key key,
      @required this.label,
      this.icon,
      this.color,
      this.textColor,
      this.onTap,
      this.elevated = false,
      this.radius = 15,
      this.height = 30})
      : super(key: key);

  final String label;
  final Widget icon;
  final VoidCallback onTap;
  final Color color, textColor;
  final bool elevated;
  final double radius;
  final double height;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: color ?? RiveTheme.of(context).colors.commonButtonColor,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: elevated
              ? [
                  BoxShadow(
                    color: RiveTheme.of(context)
                        .colors
                        .commonDarkGrey
                        .withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 8),
                  )
                ]
              : null,
        ),
        height: height,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              label,
              style: TextStyle(
                color: textColor ??
                    RiveTheme.of(context).colors.commonButtonTextColor,
                fontSize: 13,
              ),
            ),
            if (icon != null) ...[icon],
          ],
        ),
      ),
    );
  }
}
