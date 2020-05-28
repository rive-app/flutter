import 'package:admin/impersonate.dart';
import 'package:admin/signout.dart';
import 'package:admin/token_generator.dart';
import 'package:flutter/material.dart';

class AdminView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdminPageButton('Impersonate'),
            AdminPageButton('Invite'),
            SizedBox(height: 30),
            Signout(),
          ],
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
          MaterialPageRoute(
            builder: (pageContext) => Scaffold(
                appBar: AppBar(
                  title: Text(routeName),
                ),
                body: _routeNameToPage[routeName]),
          ),
        );
      },
    );
  }
}

final _routeNameToPage = <String, Widget>{
  'Impersonate': Impersonate(),
  'Invite': TokenGenerator()
};
