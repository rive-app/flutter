import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/theme.dart';

class IconTile extends StatelessWidget {
  const IconTile({
    Key key,
    @required this.label,
    @required this.icon,
    this.onTap,
  }) : super(key: key);

  final String label;
  final VoidCallback onTap;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(
          right: 20.0,
          top: 20.0,
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 15,
              height: 15,
              child: Center(child: icon),
            ),
            Container(width: 15.0),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: ThemeUtils.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
