import 'package:flutter/material.dart';

import 'package:rive_api/models/user.dart';

import 'package:rive_editor/widgets/icons.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/common/flat_icon_button.dart';
import 'package:rive_editor/widgets/common/inspector_view.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var rive = RiveContext.of(context);
    ;
    return InspectorView(
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            child: Icon(Icons.person),
          ),
          Container(height: 10),
          ValueListenableBuilder<RiveUser>(
            valueListenable: rive.user,
            builder: (context, user, _) => Text(
              user.name ?? user.username,
              style: RiveTheme.of(context).textStyles.fileGreyTextLarge,
            ),
          ),
          Container(height: 10),
          Text(
            "This is where your personal files live.",
            style: RiveTheme.of(context).textStyles.fileLightGreyText,
          ),
        ],
      ),
      actions: const <Widget>[
        FlatIconButton(
          icon: ProfileIcon(),
          label: 'Your Profile',
        ),
        FlatIconButton(
          icon: SettingsIcon(),
          label: 'Settings',
        ),
      ],
    );
  }
}
