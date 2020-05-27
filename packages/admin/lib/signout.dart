import 'package:admin/manager.dart';
import 'package:flutter/material.dart';
import 'package:rive_api/models/user.dart';

class Signout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        StreamBuilder<RiveUser>(
          stream: AdminManager.instance.user,
          builder: (context, snapshot) {
            var user = snapshot.hasData ? snapshot.data : null;
            return user == null
                ? SizedBox()
                : Text('Signed in as: ${user.displayName}\n\n'
                    'Signout to login as another user, note that this will sign'
                    ' you out of the Rive app (next time you start it).');
          },
        ),
        RaisedButton(
          child: Text('Signout'),
          onPressed: () {
            AdminManager.instance.signout().then(
              (value) {
                Scaffold.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Signout ${value ? 'success' : 'failed'}'),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
