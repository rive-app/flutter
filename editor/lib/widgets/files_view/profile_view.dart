import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/common/flat_icon_button.dart';
import 'package:rive_editor/widgets/common/inspector_view.dart';
import 'package:rive_editor/widgets/theme.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InspectorView(
      header: Column(
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
      actions: <Widget>[
        FlatIconButton(
          icon: RiveIcons.profile(ThemeUtils.iconColor),
          label: "Your Profile",
        ),
        FlatIconButton(
          icon: RiveIcons.settings(ThemeUtils.iconColor),
          label: "Settings",
        ),
      ],
    );
  }
}
