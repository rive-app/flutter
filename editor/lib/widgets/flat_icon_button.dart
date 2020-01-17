import 'package:flutter/material.dart';

import 'theme.dart';

class FlatIconButton extends StatelessWidget {
  const FlatIconButton({
    Key key,
    @required this.label,
    this.icon,
    this.onTap,
  }) : super(key: key);

  final String label;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: ThemeUtils.buttonColor,
          borderRadius: BorderRadius.circular(20.0),
        ),
        height: 30,
        child: Row(
          children: <Widget>[
            if (icon != null) ...[
              Container(width: 15.0),
              icon,
            ],
            Container(width: 15.0),
            Text(
              label,
              style: TextStyle(
                color: ThemeUtils.buttonTextColor,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
