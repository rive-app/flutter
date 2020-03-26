import 'package:flutter/material.dart';

import 'package:rive_editor/widgets/inherited_widgets.dart';

class IconTile extends StatelessWidget {
  const IconTile({
    @required this.label,
    @required this.icon,
    this.onTap,
    Key key,
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
          right: 20,
          top: 20,
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 15,
              height: 15,
              child: Center(child: icon),
            ),
            Container(width: 5),
            Text(
              label,
              style: RiveTheme.of(context).textStyles.fileLightGreyText,
            ),
          ],
        ),
      ),
    );
  }
}
