import 'package:admin/manager.dart';
import 'package:flutter/material.dart';

class Impersonate extends StatefulWidget {
  @override
  _ImpersonateState createState() => _ImpersonateState();
}

class _ImpersonateState extends State<Impersonate> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();

  bool _impersonationFailed = false;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(height: 20),
          Text('Impersonate another Rive user. Use this to view the app from '
              'their perspective, careful as the app is fully functional so '
              'you\'ll be using it as them. Note that you\'ll also lose '
              'access to the admin tool once the impersonation succeeds, '
              'unless you are impersonating another admin.'),
          TextFormField(
            decoration: InputDecoration(labelText: 'Username'),
            controller: _username,
            validator: (value) {
              if (_impersonationFailed) {
                return 'Failed, check username is correct.';
              }
              if (value.isEmpty) {
                return 'Enter username';
              }
              return null;
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: RaisedButton(
              onPressed: () async {
                if (_formKey.currentState.validate()) {
                  Scaffold.of(context).showSnackBar(
                      SnackBar(content: Text('Impersonating...')));
                  var result =
                      await AdminManager.instance.impersonate(_username.text);
                  if (!result) {
                    // Hack it up! Re-rerun but this time our username will show
                    // there was a credential error.
                    _impersonationFailed = true;
                    _formKey.currentState.validate();
                    _impersonationFailed = false;
                  }
                }
              },
              child: Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }
}
