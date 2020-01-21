import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/theme.dart';

class FlatIconButton extends StatelessWidget {
  const FlatIconButton({
    Key key,
    @required this.label,
    this.icon,
    this.color,
    this.textColor,
    this.onTap,
    this.elevated = false,
  }) : super(key: key);

  final String label;
  final Widget icon;
  final VoidCallback onTap;
  final Color color, textColor;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.0),
        decoration: BoxDecoration(
          color: color ?? ThemeUtils.buttonColor,
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: elevated
              ? [
                  BoxShadow(
                    color: ThemeUtils.textGrey.withOpacity(0.1),
                    blurRadius: 12,
                    offset: Offset(0, 8),
                  )
                ]
              : null,
        ),
        height: 30,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              label,
              style: TextStyle(
                color: textColor ?? ThemeUtils.buttonTextColor,
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
