import 'package:flutter/material.dart';

import 'flat_icon_button.dart';
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
          Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                CircleAvatar(
                  child: Icon(Icons.person),
                ),
                Container(height: 10.0),
                Text(
                  "Guido's Files",
                  style: Theme.of(context).textTheme.headline,
                ),
                Container(height: 10.0),
                Text(
                  "This is where your personal files live.",
                  style: Theme.of(context)
                      .textTheme
                      .subhead
                      .copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
          Column(
            children: <Widget>[
              FlatIconButton(
                icon: Icon(
                  Icons.person_outline,
                  color: ThemeUtils.buttonTextColor,
                ),
                // icon: PathWidget(
                //   path: ThemeUtils.profileIcon2,
                //   nudge: Offset(0.5, 0.5),
                //   paint: Paint()
                //     ..color = ThemeUtils.iconColor
                //     ..style = PaintingStyle.stroke
                //     ..isAntiAlias = true,
                // ),
                label: "Your Profile",
              ),
              Container(height: 20.0),
              FlatIconButton(
                icon: Icon(
                  Icons.settings,
                  color: ThemeUtils.buttonTextColor,
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
