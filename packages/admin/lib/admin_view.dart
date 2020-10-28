import 'package:admin/api_choser.dart';
import 'package:admin/impersonate.dart';
import 'package:admin/signout.dart';
import 'package:admin/teams.dart';
import 'package:admin/charges.dart';
import 'package:admin/transactions.dart';
import 'package:admin/token_generator.dart';
import 'package:admin/users.dart';
import 'package:admin/announcements.dart';
import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

class AdminView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RiveTheme(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 500,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AdminPageButton('Impersonate'),
              const AdminPageButton('Invite'),
              const AdminPageButton('Users'),
              const AdminPageButton('Teams'),
              const AdminPageButton('Charges'),
              const AdminPageButton('Transactions'),
              const AdminPageButton('Announcements'),
              const SizedBox(height: 30),
              Signout(),
              Expanded(child: ApiChoser())
            ],
          ),
        ),
      ),
    );
  }
}

class AdminPageButton extends StatelessWidget {
  const AdminPageButton(this.routeName, {Key key}) : super(key: key);

  final String routeName;

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      child: Text(routeName),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (pageContext) => Scaffold(
                appBar: AppBar(
                  title: Text(routeName),
                ),
                body: RiveTheme(child: _routeNameToPage[routeName])),
          ),
        );
      },
    );
  }
}

final _routeNameToPage = <String, Widget>{
  'Impersonate': Impersonate(),
  'Invite': TokenGenerator(),
  'Teams': const Teams(),
  'Charges': const Charges(),
  'Transactions': const Transactions(),
  'Announcements': const Announcements(),
  'Users': const Users(),
};
