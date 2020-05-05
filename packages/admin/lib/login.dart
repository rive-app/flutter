import 'package:admin/manager.dart';
import 'package:flutter/material.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();

  bool _credentialsFailed = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextFormField(
              decoration: InputDecoration(labelText: 'Username'),
              controller: _username,
              validator: (value) {
                if (_credentialsFailed) {
                  return 'Failed, '
                      'check your username & password.';
                }
                if (value.isEmpty) {
                  return 'Enter username';
                }
                return null;
              },
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Password'),
              controller: _password,
              obscureText: true,
              validator: (value) {
                if (_credentialsFailed) { 
                  return '';
                }
                if (value.isEmpty) {
                  return 'Enter password';
                }
                return null;
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: RaisedButton(
                onPressed: () async {
                  if (_formKey.currentState.validate()) {
                    Scaffold.of(context)
                        .showSnackBar(SnackBar(content: Text('Logging in...')));
                    var result = await AdminManager.instance
                        .login(_username.text, _password.text);
                    if (result.isError) {
                      // Hack it up! Re-rerun but this time our username will show
                      // there was a credential error.
                      _credentialsFailed = true;
                      _formKey.currentState.validate();
                      _credentialsFailed = false;
                    }
                  }
                },
                child: Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
