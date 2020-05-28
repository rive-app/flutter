import 'package:admin/manager.dart';
import 'package:flutter/material.dart';

class TokenGenerator extends StatefulWidget {
  @override
  _TokenGeneratorState createState() => _TokenGeneratorState();
}

class _TokenGeneratorState extends State<TokenGenerator> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  final _emailValidator = RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$");

  bool _hasError = false;

  bool isEmailValid(String input) => _emailValidator.hasMatch(input);

  void get _clearError {
    if (_hasError) {
      setState(() {
        _hasError = false;
      });
    }
  }

  void _showSnackBar(BuildContext context, String message) =>
      Scaffold.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invite someone via email.\n'
                'An email will be sent to the email address input below '
                'with a link to sign-up'),
            TextFormField(
              decoration: InputDecoration(labelText: 'Email'),
              controller: _email,
              onChanged: (_) => _clearError,
              validator: (value) {
                if (_hasError) {
                  return 'Couldn\'t send invite.';
                }
                if (value.isEmpty) {
                  return 'Enter email';
                }
                if (!isEmailValid(value)) {
                  return 'Not a valid email address';
                }
                return null;
              },
            ),
            SizedBox(height: 30),
            RaisedButton(
              child: Text('Generate'),
              onPressed: () async {
                _showSnackBar(context, 'Generating...');
                if (_formKey.currentState.validate()) {
                  var result = await AdminManager.instance.invite(_email.text);
                  if (!result) {
                    setState(() {
                      _hasError = true;
                    });
                  } else {
                    _showSnackBar(context, 'Success!');
                  }
                } else {
                  _showSnackBar(context, 'Something went wrong.');
                }
              },
            )
          ],
        ),
      ),
    );
  }
}
