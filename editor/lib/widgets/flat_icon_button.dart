import 'package:flutter/material.dart';

import 'theme.dart';

class FlatIconButton extends StatelessWidget {
  const FlatIconButton({
    Key key,
    @required this.label,
    @required this.icon,
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
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: <Widget>[
              Container(width: 10.0),
              icon,
              Container(width: 10.0),
              Text(
                label,
                style: TextStyle(color: ThemeUtils.buttonTextColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
