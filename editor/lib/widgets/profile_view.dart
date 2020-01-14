import 'package:flutter/material.dart';

import 'flat_icon_button.dart';
import 'path_widget.dart';
import 'theme.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CircleAvatar(
                child: Icon(Icons.person),
              ),
              Container(height: 10.0),
              Text(
                "Guido's Files",
                style: TextStyle(
                  fontSize: 16,
                  color: ThemeUtils.textGrey,
                ),
              ),
              Container(height: 10.0),
              Text(
                "This is where your personal files live.",
                style: TextStyle(
                  fontSize: 13,
                  color: ThemeUtils.backgroundDarkGrey,
                ),
              ),
            ],
          ),
          Column(
            children: <Widget>[
              FlatIconButton(
                icon: PathWidget(
                  path: ThemeUtils.profileIcon,
                  nudge: Offset(0.5, 0.5),
                  paint: Paint()
                    ..color = ThemeUtils.iconColor
                    ..style = PaintingStyle.fill
                    ..isAntiAlias = true,
                ),
                label: "Your Profile",
              ),
              Container(height: 20.0),
              FlatIconButton(
                icon: PathWidget(
                  path: ThemeUtils.settingsIcon,
                  nudge: Offset(0.5, 0.5),
                  paint: Paint()
                    ..color = ThemeUtils.iconColor
                    ..style = PaintingStyle.fill
                    ..isAntiAlias = true,
                ),
                label: "Settings",
              ),
            ],
          ),
        ],
      ),
    );
  }
}
